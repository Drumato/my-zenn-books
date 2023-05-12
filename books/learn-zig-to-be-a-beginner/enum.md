---
title: "enum"
free: true
---

# enum

列挙型と呼ばれるenumについて見ていきます、
次の章の `union` と合わせて、Rustの`enum`のように便利なデータ型を実現することもできる、
Zigプログラミングで重要な機能になります。

## 基本

ともかく、まずは使ってみましょう。

```zig
const std = @import("std");

const E = enum { a, b, c, d };

test "test" {
    const e1 = E.a;
    try std.testing.expectEqual(e1, E.a);
}
```

これはCのenumに近いもののように見えます。

```c
#include <stdio.h>

enum E {
  A,
  B,
  C,
  D,
};

int main(void) {
  const enum E e = A;

  printf("%s\n", e == A ? "true" : "false");
}
```

## enumが取りうる整数値の型指定

enumが取りうる値として、型を渡すことができます。

```zig
const std = @import("std");

const CurrentStatus = enum(u1) {
    started,
    stopped,
    // これ以上ヴァリアントを増やすことはできない
    // Restarted,
};

test "test" {
    const e1 = CurrentStatus.started;
    try std.testing.expectEqual(e1, CurrentStatus.started);
}
```

enumの整数値に変換する `@enumToInt` を利用して、
以下のような前後関係の比較も行えます。

```zig
const std = @import("std");

const Logger = struct {
    level: LogLevel,

    fn enabled(self: @This(), level: LogLevel) bool {
        return @enumToInt(self.level) >= @enumToInt(level);
    }
};

const LogLevel = enum {
    trace,
    debug,
    info,
    warn,
    fatal,
};

test "test" {
    const logger = Logger{ .level = LogLevel.warn };
    try std.testing.expect(logger.enabled(LogLevel.info));
}
```

## enumの型名を省略してリテラルを使う

```zig
const std = @import("std");

const E = enum {
    a,
    b,
    c,
    d,
};

test "test" {
    const e1: E = .a;
    try std.testing.expectEqual(e1, .a);
}
```

この機能は、後々解説するswitch式で非常に有用です。
それぞれのケースにて、冗長な記述を避けることができます。

```zig
const std = @import("std");

const E = enum {
    a,
    b,
    c,
    d,
};

test "test" {
    const e1: E = .a;
    const s = switch (e1) {
        .a => "A",
        .b => "B",
        else => "?",
    };

    try std.testing.expect(std.mem.eql(u8, s, "A"));
}
```

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#enum>

