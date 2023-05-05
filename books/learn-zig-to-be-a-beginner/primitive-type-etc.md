---
title: "その他のプリミティブ型"
free: true
---

# その他のプリミティブ型

この章では、残りのプリミティブ型についてささっと解説していきます。

## 浮動小数点数型

## bool

論理和/論理積の演算子が `and/or` である点に注目です。なんとなくPythonを思い浮かべますね。

```zig
const std = @import("std");

test "test" {
    // trueおよびfalseは "Primitive Values"として定義されている
    const a = true;
    const b = false;

    // 真偽の反転
    try std.testing.expect(!b);
    // 短絡評価ありの論理和演算
    try std.testing.expect(a and b);
    // 短絡評価ありの論理積演算
    try std.testing.expect(a or b);
}
```

## 浮動小数点数

```zig
const std = @import("std");

test "test" {
    const a: f32 = 0.001;
    const b: f64 = 0.002;
    const c = a + b;

    // Peer Type Resolutionが適用される
    try std.testing.expectEqual(f64, @TypeOf(c));
}
```

## void

関数が値を返さないときに使われる `void` ですが、
データ構造のうち一部の値が意味を持たない場合に、それを `void` とするユースケースがあります。

公式ドキュメントでは、マップの値の型を `void` として、
マップをセットとして用いる方法が紹介されています。
また、`void` 型の値を生成したい場合には、 `.{}` とします。
`void` 型はコンパイル時にサイズが決まっており、0ビットだと定められています。

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Primitive-Types>
- <https://ziglang.org/documentation/0.10.1/#Primitive-Values>
- <https://ziglang.org/documentation/0.10.1/#Integers>
- <
