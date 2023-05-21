---
title: "Zigの関数"
free: true
---

# Zigの関数

ここまでたくさん使ってきたZigの関数ですが、さらにいくつかのトピックについて追加で解説したいと思います。

## 関数ポインタ

C言語で使われることの多い関数ポインタですが、Zigでも用いることができます。
Cの関数ポインタの型シグネチャは初見だと難しいですが、
Zigの場合は関数定義の文法のように記述できるので、かんたんに理解できると思います。

```zig
const std = @import("std");

fn cast(x: i32) i64 {
    return @as(i64, x);
}

fn add_cast(x: i32) i64 {
    return @as(i64, x) + 1;
}

fn apply(f: *const fn (x: i32) i64, x: i32) i64 {
    return f(x);
}

test "test" {
    // 関数も型を持つ
    try std.testing.expectEqual(fn (x: i32) i64, @TypeOf(cast));
    try std.testing.expectEqual(fn (f: *const fn (x: i32) i64, x: i32) i64, @TypeOf(apply));

    try std.testing.expect(apply(cast, 1) == 1);
    try std.testing.expect(apply(add_cast, 1) == 2);
}
```

## ジェネリックな関数

関数の引数として、ジェネリックな型を渡すこともできます。

```zig
const std = @import("std");

fn f(
    comptime T: type,
    comptime U: type,
    inner_f: *const fn (t: T) U,
    t: T,
) U {
    return inner_f(t);
}

fn i32_cast(x: i32) i64 {
    return @as(i64, x);
}

fn u32_cast(x: u32) u64 {
    return @as(u64, x);
}

test "test" {
    try std.testing.expect(f(i32, i64, i32_cast, 2) == 2);
    try std.testing.expect(f(u32, u64, u32_cast, 2) == 2);
}
```

## ジェネリックな型定義

ジェネリックな関数定義のテクニックを利用して、
ジェネリックな型パラメータを持つ構造体を定義することができます。
これはよく使われるテクニックです。

```zig
const std = @import("std");

fn GenericS(comptime T: type) type {
    return struct {
        value: T,

        fn init(v: T) @This() {
            return @This(){ .value = v };
        }
    };
}

test "test" {
    const s1 = GenericS(i32).init(42);
    const s2 = GenericS([]const u8).init("Drumato");

    try std.testing.expect(s1.value == 42);
    try std.testing.expect(std.mem.eql(u8, "Drumato", s2.value));
}
```

