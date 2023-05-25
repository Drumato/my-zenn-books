---
title: "GNU coreutils lsライクななにかを作ってみる"
free: true
---

# GNU coreutils lsライクななにか作ってみる

次に、 `ls` コマンドっぽいものを作ってみることにします。
以下のオプションに対応することを目指しましょう。

- `-l` ... 詳細な情報を出力する
- `-a` ... hidden fileも合わせて出力する
- `-i` ... inode番号を表示する

いつもどおり、プロジェクトを作ってみます。

```
$ mkdir ls-subset && cd ls-subset
$ zig init-exe
```

## ビルドスクリプトでフォーマットを実行する

生成された build.zig で、 `zig fmt` が自動実行されるように編集しましょう。


```dif
const std = @import("std");

+ const fmt_paths = [_][]const u8{
+     "src",
+ };

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("ls-subset", "src/main.zig");

+   const fmt_step = b.addFmt(&fmt_paths);
+   exe.step.dependOn(&fmt_step.step);

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
```

## 基本機能

まずは、コマンドライン引数で渡されたディレクトリ内のエントリ名を表示する基本機能を作ってみます。
`std.fs.cwd()` でカレントディレクトリを表す `std.fs.Dir` から、
渡されたディレクトリに対応する `std.fs.IterableDir` を取得します。

これをイテレートして名前を出力してみると、
(lsコマンドと違って辞書順にソートされないものの)似たような結果を得ることができます。

`while (try target_dir_entries.next()) |target_dir_entry|` は、かっこの中の式がOptional型を返す場合に、
`null` を返さない間ループしてくれる機能です。

```zig
const std = @import("std");

pub fn main() !void {
    var args = std.process.ArgIterator.init();
    std.debug.assert(args.next() != null);

    var stdout = std.io.getStdOut().writer();

    while (args.next()) |arg| {
        const cwd = std.fs.cwd();

        const target_dir = if (std.fs.path.isAbsolute(arg)) blk: {
            break :blk try std.fs.openIterableDirAbsolute(arg, std.fs.Dir.OpenDirOptions{});
        } else else_blk: {
            break :else_blk try cwd.openIterableDir(arg, std.fs.Dir.OpenDirOptions{});
        };

        var target_dir_entries = target_dir.iterate();
        while (try target_dir_entries.next()) |target_dir_entry| {
            try stdout.print("{s} ", .{target_dir_entry.name});
        }
    }
}
```

```shell
$ zig build
$ ./zig-out/bin/ls-subset /
dev var lost+found opt etc sys mnt lib usr root srv sbin tmp home snap boot lib64 recovery media libx32 bin proc lib32 run
```

## `-a` オプションを作ってみる

次は `.` から始まるファイル等も出力してくれる、 `-a` を作ってみます。
適当に一時的なディレクトリを作って、テスト用ファイルをおいておきます。

```shell
$ mkdir ~/tmp
$ touch ~/tmp/.a
$ touch ~/tmp/.b
$ touch ~/tmp/c
```

おもむろに今の実装で指定してみると、このようなファイルも出力されてしまっているのがわかります。

```shell
$ ./zig-out/bin/ls-subset ~/tmp
c .a .b ⏎                                                                                                                                                                                                          drumato@pop-os ~/g/g/D/m/b/learn-zig-to-be-a-beginner (main)> /usr/bin/ls ~/tmp
$ /usr/bin/ls ~/tmp # 下記のようになってほしい
c
```

ということで、`..` や `.` のようなエントリが表示される前に、
まずは `-a` が指定されていなければ、`.a` や `.b` を表示しない機能を追加します。

コマンドライン引数の処理が複雑になりそうなので、別に関数を用意します。
今回は、メモリアロケータを使わないで実装してみるということで、
`std.ArrayList([]const u8)` ではなく、 `[N][]const u8` を使ってみます。

```zig
const maximum_target_count: usize = 32;
const CommandLineOption = struct {
    targets: [maximum_target_count][]const u8 = undefined,
    target_count: usize = 0,
    all_files: bool = false,
};

const CmdArgsParseError = error{
    MaximumTargetCountReached,
};

fn parseCmdArgs(
    args: *std.process.ArgIterator,
) CmdArgsParseError!CommandLineOption {
    var opt = CommandLineOption{};
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-a")) {
            opt.all_files = true;
            continue;
        }

        if (opt.target_count == 32) {
            return CmdArgsParseError.MaximumTargetCountReached;
        }

        opt.targets[opt.target_count] = arg;
        opt.target_count += 1;
    }

    return opt;
}
```

あとは、これを利用してmain関数を置き換えればOKです。
`while (condition_expression) : (poststep_expression)` を利用して、
ループのたびにインデックスを更新します。

```zig
pub fn main() !void {
    var args = std.process.ArgIterator.init();
    std.debug.assert(args.next() != null);

    const opt = try parseCmdArgs(&args);
    var stdout = std.io.getStdOut().writer();

    var index: usize = 0;
    while (index < opt.target_count) : (index += 1) {
        const target_path = opt.targets[index];

        const cwd = std.fs.cwd();

        const target_dir = if (std.fs.path.isAbsolute(target_path)) blk: {
            break :blk try std.fs.openIterableDirAbsolute(target_path, std.fs.Dir.OpenDirOptions{});
        } else else_blk: {
            break :else_blk try cwd.openIterableDir(target_path, std.fs.Dir.OpenDirOptions{});
        };

        var target_dir_entries = target_dir.iterate();
        while (try target_dir_entries.next()) |target_dir_entry| {
            const hide_file = !opt.all_files;
            if (hide_file and target_dir_entry.name[0] == '.') {
                continue;
            }

            try stdout.print("{s} ", .{target_dir_entry.name});
        }
    }
}
```

```shell
$ ./zig-out/bin/ls-subset ~/tmp
c ⏎                                                                                                                                                                                                                drumato@pop-os ~/g/g/D/m/b/l/ls-subset (main)> ./zig-out/bin/ls-subset -a ~/tmp
$ ./zig-out/bin/ls-subset -a ~/tmp
c .a .b
```

## inode番号を表示する

TODO

