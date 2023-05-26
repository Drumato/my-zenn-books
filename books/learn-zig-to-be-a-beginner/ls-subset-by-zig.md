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


```diff
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
ちなみに、今回は `.` や `..` は扱わないことにします。
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
c .a .b
$ /usr/bin/ls ~/tmp # 下記のようになってほしい
c
```

まずは `-a` が指定されていなければ、`.a` や `.b` を表示しない機能を追加します。
コマンドライン引数の処理が複雑になりそうなので、別に関数を用意します。
今回はメモリアロケータを利用して、 `std.ArrayList([]const u8)` を使ってみます。

```zig
const CommandLineOption = struct {
    targets: std.ArrayList([]const u8),
    all_files: bool = false,
    show_inode_number: bool = false,
};

const CmdArgsParseError = error{
    MaximumTargetCountReached,
} || std.mem.Allocator.Error;

fn parseCmdArgs(
    allocator: std.mem.Allocator,
    args: *std.process.ArgIterator,
) CmdArgsParseError!CommandLineOption {
    var opt = CommandLineOption{
        .targets = std.ArrayList([]const u8).init(allocator),
    };
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-a")) {
            opt.all_files = true;
            continue;
        }

        try opt.targets.append(arg);
    }

    return opt;
}
```

あとは、これを利用してmain関数を置き換えればOKです。

```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.ArgIterator.init();
    std.debug.assert(args.next() != null);

    const opt = try parseCmdArgs(allocator, &args);
    defer opt.targets.deinit();

    var stdout = std.io.getStdOut().writer();

    for (opt.targets.items) |target_path| {
        const cwd = std.fs.cwd();

        const target_dir = if (std.fs.path.isAbsolute(target_path)) blk: {
            break :blk try std.fs.openIterableDirAbsolute(target_path, std.fs.Dir.OpenDirOptions{});
        } else else_blk: {
            break :else_blk try cwd.openIterableDir(target_path, std.fs.Dir.OpenDirOptions{});
        };

        const target_dir_entries = try collectFileInformation(allocator, target_dir);
        const hide_file = !opt.all_files;
        for (target_dir_entries.items) |target_dir_entry| {
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
c
$ ./zig-out/bin/ls-subset -a ~/tmp
c .a .b
```

## inode番号を表示する

続いてinode番号を表示する `-i` オプションを作ってみます。
まずはさくっとオプション解析部分を変更します。

```zig
const CommandLineOption = struct {
    targets: std.ArrayList([]const u8),
    all_files: bool = false,
    show_inode_number: bool = false, // 追加
};

fn parseCmdArgs(
    allocator: std.mem.Allocator,
    args: *std.process.ArgIterator,
) CmdArgsParseError!CommandLineOption {
    var opt = CommandLineOption{
        .targets = std.ArrayList([]const u8).init(allocator),
    };
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-a")) {
            opt.all_files = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-i")) { // 追加
            opt.show_inode_number = true;
            continue;
        }

        try opt.targets.append(arg);
    }

    return opt;
}
```

次にinode番号を取得するロジックです。
現在は `std.fs.IterableDir.Entry` のそれぞれから `name` メンバを出力していますが、
この型はinode番号を持っていないので、少し大きな改変が必要です。
一方、ドキュメントを読んでみると、 `std.fs.Dir` と `std.fs.File` には `stat()` が存在し、
これによって得られる `std.fs.Dir.Stat/std.fs.File.Stat` は `inode` を持っていることがわかります。

ということで、うまく各 `std.fs.IterableDir.Entry` を `std.fs.Dir/std.fs.File` に変換すれば良さそうです。
これは、 `kind` というメンバを利用して実現できます。
なお、今回は `.NamedPipe` や `.BlockDevice` などのkindには対応しないことにします。

```zig
const FileInformation = struct {
    name: []const u8,
    inode: u64,
};

fn collectFileInformation(
    allocator: std.mem.Allocator,
    target_dir: std.fs.IterableDir,
) !std.ArrayList(FileInformation) {
    var files = std.ArrayList(FileInformation).init(allocator);

    var iterator = target_dir.iterate();
    while (try iterator.next()) |dir_entry| {
        const file = switch (dir_entry.kind) {
            .File => file_blk: {
                const file = try target_dir.dir.openFile(dir_entry.name, std.fs.File.OpenFlags{});
                const stat = try file.stat();
                break :file_blk FileInformation{
                    .name = dir_entry.name,
                    .inode = stat.inode,
                };
            },
            .Directory => dir_blk: {
                const dir = try target_dir.dir.openDir(dir_entry.name, std.fs.Dir.OpenDirOptions{});
                const stat = try dir.stat();
                break :dir_blk FileInformation{
                    .name = dir_entry.name,
                    .inode = stat.inode,
                };
            },
            else => unreachable,
        };
        try files.append(file);
    }

    return files;
}
```

あとはmain関数側を書き換えます。
お行儀の良いコードとして、`deinit()` を呼ぶのを忘れないでください。

```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.ArgIterator.init();
    std.debug.assert(args.next() != null);

    const opt = try parseCmdArgs(allocator, &args);
    defer opt.targets.deinit();

    var stdout = std.io.getStdOut().writer();
    for (opt.targets.items) |target_path| {
        const cwd = std.fs.cwd();

        const target_dir = if (std.fs.path.isAbsolute(target_path)) blk: {
            break :blk try std.fs.openIterableDirAbsolute(target_path, std.fs.Dir.OpenDirOptions{});
        } else else_blk: {
            break :else_blk try cwd.openIterableDir(target_path, std.fs.Dir.OpenDirOptions{});
        };

        const target_dir_entries = try collectFileInformation(allocator, target_dir);
        const hide_file = !opt.all_files;
        for (target_dir_entries.items) |target_dir_entry| {
            if (hide_file and target_dir_entry.name[0] == '.') {
                continue;
            }

            if (opt.show_inode_number) {
                try stdout.print("{s}:{} ", .{ target_dir_entry.name, target_dir_entry.inode });
            } else {
                try stdout.print("{s} ", .{target_dir_entry.name});
            }
        }
    }
}
```

いろいろ試してみましょう。

```shell
$ ./zig-out/bin/ls-subset ~/tmp
c .a .b
$ ./zig-out/bin/ls-subset -a ~/tmp
c:5280124
$ ./zig-out/bin/ls-subset -a -i ~/tmp
c:5280124 .a:5280081 .b:5280121
$ ./zig-out/bin/ls-subset -a -i ~/tmp
5280064 ./  2097154 ../  5280081 .a  5280121 .b  5280124 c
```

## `-l` で詳細な情報を出力する

TODO

