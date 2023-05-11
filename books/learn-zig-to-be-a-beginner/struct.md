---
title: "構造体型"
free: true
---

# 構造体型

Zigで扱われる標準的なコンテナ型として、構造体型が存在します。
これはGoやRust、C言語等で使われるものなので、比較的馴染み深いと思います。
ただし、Zigの構造体はこれらとは異なる機能も存在しているので、すこし詳しめに解説します。

## 基本的な使い方

CやRust, Goと違って、型定義すらも式であるというところがZigの面白いポイントです。
構造体型を定義するには、`struct {};` という式を使います。
単純な型定義については、整数型の解説でTCPセグメントヘッダを定義した部分でお見せしたので、
ここでは、今までに紹介した型をいろいろ出演させてみます。

```zig
const std = @import("std");

const S = struct {
    int: isize,
    float: f64,
    bool: bool,
    // voidをもたせることもできる
    void: void,
    type: type,
    array: [5]isize,
    slice: []const u8,
    option: ?isize,
    pointer: *const isize,
};

test "test" {
    const base_int: isize = 42;
    const s = S{
        .int = 1,
        .float = 2.0,
        .bool = true,
        .void = {},
        .type = S,
        .option = 3,
        .array = .{ 4, 5, 6, 7, 8 },
        .slice = "Drumato",
        .pointer = &base_int,
    };

    try std.testing.expectEqual(s.type, @TypeOf(s));
}
```

## メソッド

構造体にはメソッドを定義することができます。
Rustは `impl` ブロックを別に用意して定義し、
Goは関数定義の際にレシーバを明記して定義しますが、
Zigは `struct {}` スコープの中にそのまま定義します。
これはC++でも可能な書き方です。

以下にサンプルを示します。
メソッドの第一引数と、それによる使われ方に違いに注目してください。

```zig
const std = @import("std");

const S = struct {
    v: isize,

    fn value(self: @This()) isize {
        return self.v;
    }

    fn set_value(self: *@This(), new_v: isize) void {
        self.v = new_v;
    }

    fn associated_fn() isize {
        return 30;
    }
};

test "test" {
    var s = S{ .v = 42 };
    try std.testing.expect(s.value() == 42);

    s.set_value(43);
    try std.testing.expect(s.value() == 43);

    // 関連関数であり、メソッドではない点に注意
    try std.testing.expect(S.associated_fn() == 30);
}
```

ここで、 `@This()` という組み込み関数は、
現在のスコープ内でinnermostに見つかる型定義の型を表します。
ここでは、 `S` と読み替えていただいてかまいません。
`value()/set_value()` の違いを見ると、第一引数に `*` がついているかどうかが見て取れます。
これは、Goでメソッドを定義するときの文法に似たようなもので、
レシーバとなっている `self` が可変ポインタなのかどうかが変わります。

そして `associated_fn` は関連関数なので、型名をレシーバとして呼び出します。
これは、Rustでも利用できる機能です。
<https://doc.rust-jp.rs/book-ja/ch05-03-method-syntax.html#%E9%96%A2%E9%80%A3%E9%96%A2%E6%95%B0>

## 構造体のスコープ

`struct {}` はそれ自体がスコープを生成し、内部で宣言を持ったり、宣言された定数にアクセスしたりできます。
これは、階層構造を持った型定義をすることが可能ということです。
具体例を以下に示します。
下の例では `const Self = @This()` を利用していますが、
コメントに書いた理由により、私は `@This()` を直接書く書き方のほうがおすすめです。

```zig
const std = @import("std");

const P = struct {
    // Selfにエイリアスするやり方がよく使われる
    // ただし、今回のような階層構造を持つ型を定義する場合は注意
    const Self = @This();

    const value = @as(i32, 1);

    const C = struct {
        const value = @as(i32, 2);

        fn f(_: @This()) i32 {
            // Zigではシャドウイングが許されておらず、必ず明示してアクセスする
            // 例えば以下のように呼び出すと、valueの宣言元がS.valueかC.valueかが曖昧となる
            // return value;
            // Selfも同様の理由により、階層構造を持つ場合は使わないほうが読みやすい

            return @This().value;
        }
    };

    fn f(_: Self) i32 {
        return value;
    }
};

test "test" {
    var p = P{};
    try std.testing.expect(p.f() == 1);

    var c = P.C{};
    try std.testing.expect(c.f() == 2);
}
```

ここで定数ではなく変数を宣言してみましょう。
結果を見るとわかりますが、スコープの中で変数の値を書き換えたりもできます。
しかし、これはコードを読みづらくするきっかけになるので、使い方には注意してください。
また、マルチスレッドプログラミング下では、排他制御を実施しなければなりません。

```
const std = @import("std");

const S = struct {
    var v = @as(isize, 42);

    fn value() isize {
        return v;
    }

    fn set_value(new_v: isize) void {
        v = new_v;
    }
};

test "test" {
    try std.testing.expect(S.value() == 42);

    S.set_value(43);
    try std.testing.expect(S.value() == 43);
}
```

## デフォルト値

構造体のメンバはデフォルト値を持つことができます。

```zig
const std = @import("std");

const S1 = struct {
    v: isize,
};

const S2 = struct {
    v: isize = 42,
};

test "test" {
    // 以下のような書き方はできず、指定する必要がある
    // const s1 = S1{};
    const s1 = S1{ .v = 0 };
    try std.testing.expect(s1.v == 0);

    const s2 = S2{};
    try std.testing.expect(s2.v == 42);
}
```

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#struct>

