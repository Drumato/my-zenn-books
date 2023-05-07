---
title: "配列型"
free: true
---

# 配列型

Zigで固定長のデータ列を扱う型として、配列型が用意されています。
コンパイラ内部で扱われる `Type` では、配列型を以下のように表現しています。

> ```zig
> pub const ArrayInfo = struct { elem_type: Type, sentinel: ?Value = null, len: u64 };
> ```
> 
> <https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/src/type.zig#L322> より引用

それぞれ、 `elem_type` は要素の型、 `len` は配列の長さ、 `sentinel` は配列の終端に置く値です。
`sentinel` については後述します。

では実際に使い方を見ていきましょう。

## 簡単な使い方

まずは配列の初期化式について見てみます。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const arr = [5]isize{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(3, arr[2]);
}
```

公式ドキュメントに記載された構文規則を以下に示します。
まとめると、
`TypeExpr "{" Expr? ( "," Expr)+ ","? }"` のようなイメージになります。

> ```
> PrimaryExpr
>     <- AsmExpr
>      / IfExpr
>      / KEYWORD_break BreakLabel? Expr?
>      / KEYWORD_comptime Expr
>      / KEYWORD_nosuspend Expr
>      / KEYWORD_continue BreakLabel?
>      / KEYWORD_resume Expr
>      / KEYWORD_return Expr?
>      / BlockLabel? LoopExpr
>      / Block
>      / CurlySuffixExpr
> 
> CurlySuffixExpr <- TypeExpr InitList?
> 
> InitList
>     <- LBRACE FieldInit (COMMA FieldInit)* COMMA? RBRACE
>      / LBRACE Expr (COMMA Expr)* COMMA? RBRACE
>      / LBRACE RBRACE
> ```
>
> <https://ziglang.org/documentation/0.10.1/#Grammar> より引用

この初期化式ですが、式の値の型が推論できるのであれば、省略することもできます。
また、初期化式中の要素数を省略することが可能です。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const arr1: [5]isize = .{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(3, arr1[2]);

    const arr2 = [_]isize{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(5, arr2.len);
}
```

もちろん、多次元配列も可能です。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const rubiks_square: [3][3]isize = .{
        .{ 2, 9, 4 },
        .{ 7, 5, 3 },
        .{ 6, 1, 8 },
    };

    try std.testing.expectEqual(3, rubiks_square[1][2]);
}
```


## 配列型で利用できる演算子

まずは、配列同士の連結です。これには `++` 演算子を使います。
連結後の配列型の要素数は自動的に推論されます。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const sub_arr1 = [_]isize{ 1, 2, 3 };
    const sub_arr2 = [_]isize{ 4, 5, 6 };
    const arr1 = sub_arr1 ++ sub_arr2;

    try std.testing.expectEqual(6, arr1.len);
    try std.testing.expectEqual(4, arr1[3]);
}
```

次に配列の繰り返しです。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const sub_arr = [_]isize{ 1, 2, 3 };
    const arr = sub_arr ** 3;

    try std.testing.expectEqual(9, arr.len);
    try std.testing.expectEqual(3, arr[8]);
}
```

この2つの演算子の優先順位ですが、
連結のほうが優先順位が低いです。
足し算、掛け算の関係と似たように考えることができます。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    const sub_arr1 = [_]isize{1, 2, 3};
    const sub_arr2 = [_]isize{4, 5};
    const arr1 = sub_arr1 ++ sub_arr2 ** 2;
    const arr2 = (sub_arr1 ++ sub_arr2) ** 2;

    try std.testing.expectEqual(7, arr1.len);
    try std.testing.expectEqual(10, arr2.len);
}
```

## Sentinel-Terminated Arrays

最後に、 **Sentinel-Terminated Arrays** について取り上げます。
これは、｢配列の長さは同じだが、末尾に番兵要素を持つ｣ 配列です。
TypeExprとして、`[Length:SentinelValue]ElementType` のような形を取ります。
実例を見てみます。

```zig
const std = @import("std");
const builtin = @import("builtin");

test "test" {
    // 要素の型の範囲なら好きな値を入れられる
    const arr = [_:255]u8{1, 2, 3};

    try std.testing.expectEqual(3, arr.len);
    try std.testing.expectEqual(255, arr[3]);
}
```

これは、C言語における文字列のように、終端に `0x00` があるが、そこにはアクセスしたくない、のような型を表現する場合に有用です。
実際、後述するスライス型でSentinel Valueを `0x00` にして、
C言語の文字列と同じように扱うような標準ライブラリ関数が存在します。

<https://ziglang.org/documentation/0.10.1/std/#root;c.printf>

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Arrays>
