---
title: "ポインタ型"
free: true
---

# ポインタ型

続いてZigのポインタについて解説します。
公式ドキュメントにあるように、Zigにはいくつかの種類のポインタがあります。
以下、実例に沿って解説していきます。

## Single-Item Pointer

Rust、Goなどのプログラミング言語で馴染み深い、通常のポインタです。
デリファレンスの演算子が後置演算であり、`.*` というシンボルがつかわれています。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const v: i32 = 42;
    const ptr = &v;

    try std.testing.expectEqual(42, ptr.*);
}
```

ここで、Zigの `const` と `var` について紹介します。

Zigでは基本的に `const` を使うことを推奨しますが、
可変の値を扱いたいときに、 `var` を使って宣言することができます。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const v1 = @as(i32, 1);
    // error: cannot assign to constant
    v1 = 3;
    var v2 = @as(i32, 2);
    // こちらは可能
    v2 = 3;
}
```

ここでポインタを考えると、4つの組み合わせが考えられます。

- `var x` を指す`var ptr_x`
- `const x` を指す`var ptr_x`
- `var x` を指す`const ptr_x`
- `const x` を指す`const ptr_x`

それぞれの挙動を表したサンプルを以下に示します。


```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    var x0 = @as(i32, 0);

    var x1 = @as(i32, 1);
    var ptr_x1 = &x1;
    try std.testing.expectEqual(*i32, @TypeOf(ptr_x1));
    try std.testing.expect(1 == ptr_x1.*);
    // 参照先を変えることは可能
    ptr_x1 = &x0;
    try std.testing.expect(ptr_x1.* == 0);
    // 参照先の値も書き換えられる
    ptr_x1 = &x1;
    ptr_x1.* = 42;
    try std.testing.expect(x1 == 42);

    const x2 = @as(i32, 1);
    var ptr_x2 = &x2;
    // 型が*const i32となっている点に注意
    try std.testing.expectEqual(*const i32, @TypeOf(ptr_x2));
    // 参照先を変えることは可能
    ptr_x2 = &x0;
    try std.testing.expect(ptr_x2.* == 0);
    // 参照先の値を書き換えることはできない
    // ptr_x2.* = 42;

    var x3 = @as(i32, 1);
    const ptr_x3 = &x3;
    try std.testing.expectEqual(*i32, @TypeOf(ptr_x3));
    // 参照先を変えることができない
    // ptr_x3 = &x0;
    // 注意!: constになっても、参照先の値を変えることはできる!
    ptr_x3.* = 42;
    try std.testing.expect(ptr_x3.* == 42);

    const x4 = @as(i32, 1);
    const ptr_x4 = &x4;
    try std.testing.expectEqual(*const i32, @TypeOf(ptr_x4));
}
```

## Many-Item Pointer

Cのポインタに近いイメージで扱えるポインタです。
メモリ上に連続して、型 `T` の値が配置されている場合に使えます。
ただし、後述するスライスと異なり、連続する値の数を保持していないため、
実行時パニックも発生せず、想定しない挙動を引き起こすおそれがあります。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const arr = [_]i32{ 1, 2, 3};
    var ptr: [*]const i32 = &arr;

    try std.testing.expect(ptr[0] == 1);
    try std.testing.expect(ptr[2] == 3);
    // 後述するスライスと異なり、参照先の長さ情報を保持していない
    _ = ptr[3];
    // ポインタ演算もできる
    ptr += 1;
    try std.testing.expect(ptr[0] == 2);
    try std.testing.expect(ptr[1] == 3);
}
```

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Pointers>
- 興味のある人は以下も
  - <https://ziglang.org/documentation/0.10.1/#volatile>
    - メモリマップドI/Oを扱うプログラムを書く際に用いられる機能です
    - Zigではポインタ型自体に `volatile` であるかどうかがマークされ、ソースコード表現の通りにコンパイルされます

