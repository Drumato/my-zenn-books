---
title: "Zigの特徴-再利用性-"
free: true
---

# Zigの再利用性

Zigの大きな特徴に、プログラムの再利用性があります。
これを理解する最もわかりやすい例は、 **`builtin` パッケージを利用した実装のスイッチング** でしょう。

Zigは、コンパイラ等が内部で設定し利用する情報等を、 `@import("builtin")` で公開しています。
以下のサンプルは、そのうちいくつかの情報を出力するものです。

```zig
const builtin = @import("builtin");
const std = @import("std"); pub fn main() void {
    std.debug.print("abi = {}\n", .{builtin.abi}); // ビルドターゲットのABI情報
    std.debug.print("cpu_architecture = {}\n", .{builtin.cpu.arch}); // ビルドターゲットのCPUアーキテクチャ
    std.debug.print("os = {}\n", .{builtin.os.tag}); // ビルドターゲットのOS
    std.debug.print("target object format = {}\n", .{builtin.object_format}); // ビルドターゲットのオブジェクトファイルフォーマット
}
```

筆者の環境では、以下のように出力されました。

```shell
$ ./sample
abi = target.Target.Abi.gnu
cpu_architecture = target.Target.Cpu.Arch.x86_64
os = target.Target.Os.Tag.linux
target object format = target.Target.ObjectFormat.elf
```

この機能を使って、複数ターゲットで動作するプログラムを記述することができます。
例えば、ターゲットOSによって異なる計算をするプログラムを記述するサンプルを以下に示します。

```zig
const builtin = @import("builtin");
const std = @import("std");

pub fn main() void {
    std.debug.print("value = {}\n", .{f(30)});
}


fn f(src: isize) isize {
    return switch (builtin.os.tag) {
        .windows => src,
        .linux => src * 2,
        else => src * 3,
    };
}
```

実際に、標準ライブラリの `std.fs` でも、ターゲットOSによって実装をスイッチするコードが利用されています。
以下のコードは<https://github.com/ziglang/zig/blob/28923474401051a9aa0bddd60904b9be64943dba/lib/std/fs/path.zig#LL222C1-L228C2>より引用しました。
`const native_os = @import("builtin").target.os.tag;` 相当のコードがファイル先頭にある点に注意してください。

```zig
pub fn isAbsolute(path: []const u8) bool {
    if (native_os == .windows) {
        return isAbsoluteWindows(path);
    } else {
        return isAbsolutePosix(path);
    }
}
```

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Compile-Variables>

