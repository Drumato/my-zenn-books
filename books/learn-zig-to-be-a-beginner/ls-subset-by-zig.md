---
title: "GNU coreutils lsのサブセットを作ってみる"
free: true
---

# GNU coreutils lsのサブセットを作ってみる

次に、 `ls` コマンドのサブセットを作ってみることにします。
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

TODO
