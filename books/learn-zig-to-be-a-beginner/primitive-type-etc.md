---
title: "その他のプリミティブ型"
free: true
---

# その他のプリミティブ型

この章では、残りのプリミティブ型についてささっと解説していきます。

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

`f32/f64/f80/f128` が存在します。それぞれ、IEEE-754-2008のbinary32/binary64/80-bit extended precision/binary128に対応しています。

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
また、`void` 型の値を生成したい場合には、 `{}` とします。
`void` 型はコンパイル時にサイズが決まっており、0バイトだと定められています。

```zig
const std = @import("std");

test "test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var map = std.AutoHashMap(i32, void).init(allocator);

    try std.testing.expect(map.capacity() == 0);

    try std.testing.expect(!map.contains(1));
    try map.put(1, {});
    try std.testing.expect(map.get(1) != null);
}
```

## noreturn

`break/continue/return/unreachable/while (true) {}` などの返り値であり、
関数宣言の際、返り値型に使用することもできます。
これは、この関数がpanic等によりプログラムを終了されることを表現する際に有用です。

```zig
const std = @import("std");

pub fn main() !void {
    if (1 == 1) {
        exit();
    }
}

fn exit() noreturn {
    std.debug.panic("panic!!!!!!", .{});
}
```

### type

これは｢型を意味する型｣です。
ここまで見てきたように、Zigでは関数の引数に型を指定したり、
型自体を返す関数を定義できたりします。

```zig
const std = @import("std");

fn Container(comptime T: type) type {
    return struct {
        member_t: T,
    };
}

test "test" {
    // 型を返す関数を利用して、構造体を初期化
    const c = Container(i32){ .member_t = 1 };
    // 型同士の比較
    try std.testing.expectEqual(Container(i32), @TypeOf(c));
    try std.testing.expectEqual(i32, @TypeOf(c.member_t));
}
```

Rustでジェネリックな型パラメータを持つ型を定義する際には、以下のようにして、型定義に直接書き込むことができます。

```rust
struct S<T> {
    value: T
}
```

Zigではこれと異なり、 `comptime T: type` を受け取って型を返す関数を定義することで実現します。
これは、`std.ArrayList(T)` などの標準ライブラリも採用している方法です。

## anyopaque

初見で読み間違える技術英単語ランキングを作ったら、上位に来る `opaque` が入っているこの型ですが、
これはCにおける `void` と同等に扱える型となっています。
ただし、 `align(8)` のようにバイトアラインメントを指定する修飾子をつけないと、
`*const isize` のようなポインタを代入できない点に注意してください。

`anyopaque` については、`std.heap.ArenaAllocator` の内部実装等で用いられていますので、
詳しくはそちらのコード等を読んでみてください。
本書では、｢とりあえず使えるようになる｣の範疇を超えているため、詳しい解説は省略します。

```zig
const std = @import("std");
const builtin = @import("builtin");

const S = struct {
    ptr: *align(8) const anyopaque,
};

test "test" {
    const isize_v: isize = 1;
    const string_v: []const u8 = "Drumato";
    const s1 = S{ .ptr = @ptrCast(*const anyopaque, &isize_v) };
    const s2 = S{ .ptr = @ptrCast(*const anyopaque, &string_v) };

    try std.testing.expect(@ptrCast(*const isize, s1.ptr).* == 1);
    try std.testing.expectEqualStrings("Drumato", @ptrCast(*const []const u8, s2.ptr).*);
}
```


### 今後の章で解説する型

Primitive Types には他にも型が存在しますが、
一部の型は別途解説したほうがわかりやすいため、本章では扱わないことにします。

- `anyerror` ... エラーハンドリングの章で解説
- `comptime_int/comptime_float` ... comptimeの章で解説

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Primitive-Types>
- <https://ziglang.org/documentation/0.10.1/#Primitive-Values>
- <https://ziglang.org/documentation/0.10.1/#Integers>

