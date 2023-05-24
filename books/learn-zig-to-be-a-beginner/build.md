---
title: "Zigのビルドスクリプト"
free: true
---

# Zigのビルドスクリプト

Zigでプロジェクトを作ってみると、 `build.zig` というファイルが出力されることがわかります。

```
$ mkdir sample && cd sample
$ zig init-exe
info: Created build.zig                                                                                  
info: Created src/main.zig                                                                                                                                                                                         
info: Next, try `zig build --help` or `zig build run`
```

これは、`zig build` 時に参照されるビルドスクリプトで、
Zigの特徴的な機能の一つとなっています。
この機能のおかげで、ZigではMakefileを用意する必要がありません。

ビルドスクリプトは `std.build` という標準ライブラリを利用して書かれておりますが、
この標準ライブラリは非常に多機能であり、Cライブラリをリンクしたりするようなケースを除いて、あまり触ることもないかもしれませんので、
ここでは詳しく解説しません。

ただし、100% Zigなプロジェクトでも有用な機能はいくつか存在するので、
せっかくなのでこのビルドスクリプトでも少し遊んでみることにします。

まずは、初期化時に作成されるスクリプトを見てみましょう。

## ビルドスクリプトを読んでみる

プロジェクトが初期化されると、 build.zig というファイルが出力されていることがわかります。
これは、`zig build` 時に参照されるビルドスクリプトで、
Zigの特徴的な機能の一つとなっています。
この機能のおかげで、ZigではMakefileを用意する必要がありません。

主に、Cライブラリをリンクしたりする際に詳しく利用することになるため、
ここでは詳しく解説しませんが、
せっかくなのでこのビルドスクリプトでも少し遊んでみることにします。

まずは、初期化時に作成されるスクリプトを見てみましょう。

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("ls-subset", "src/main.zig");
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

細かいことはおいておいて、なんとなく雰囲気がつかめると思います。
大まかには、 `zig build` の挙動と、
`zig build test`のようなステップをそれぞれ定義して、ステップごとに記述する方式です。
例えば、 `exe.setBuildMode(mode);` と、 `exe_tests.setBuildMode(mode);` で異なるビルドモードを指定することもできます。

## `zig build` で `zig build test` が呼ばれるようにする

ビルドする前に、テストがすべて通ることを確認したい場合があると思います。
ということで、 `build.zig` を改変して、それが動くようにしてみます。

```diff
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("ls-subset", "src/main.zig");
-    exe.setTarget(target);
-    exe.setBuildMode(mode);
-    exe.install();

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
    exe.step.dependOn(test_step);

+   exe.setTarget(target);
+   exe.setBuildMode(mode);
+   exe.install();
}
```

src/main.zigに、`std.testing.expect(false);` のようなテストブロックを追加してみると、
`zig build` が失敗し、実行ファイルが生成されないことがわかります。

## 余談: `zig build test` で `src` 以下のテストをすべて動かす

このビルドスクリプトを見ると、テスト対象として src/main.zig のみ追加されているように見えます。
実際、 src/main.zig で src/a.zig の関数を呼んでいたとしても、 `zig build test` では src/a.zigで定義されたテストは実行されません。

ここで、Zigでよく使われるテクニックを利用します。
src/main.zig に、以下のコードを追加します。

```zig
test {
    _ = @import("a.zig");
}
```

