---
title: "Zig構文解説-switch-"
free: true
---

# Zig構文解説-switch-

式の値によってプログラムをスイッチするのに使える構文です。
Cのswitchと異なり、Zigのswitchは式であり、Rustのmatch式と同じように扱うことができます。

```zig
const std = @import("std");

const E = enum {
    a,
    b,
};

test "test" {
    const e: E = .a;
    const c = switch (e) {
        .a => 'a',
        .b => 'a',
    };

    try std.testing.expect(c == 'a');
}
```

switch式の中で記述するケースのパターンは、柔軟に設定可能です。

```zig
const std = @import("std");

test "test" {
    const v: isize = 100;
    const i: isize = 42;
    const c = switch (i) {
        0, 1, 2, 3 => 'a',
        // inclusive rangeなパターンマッチも可能
        4...10 => 'b',
        11 => blk: {
            const x: u8 = 'c';
            break :blk x;
        },
        v => 'd',
        // パターン側の式も、コンパイル時に計算できるなら複雑にできる
        blk: {
            const x: isize = 100;
            break :blk x + 1;
        } => 'e',
        // switch ... は、マッチ対象の型が取りうる値の集合をすべてカバーするようにケースが列挙されている必要がある
        else => ' ',
    };

    try std.testing.expect(c == ' ');
}
```

