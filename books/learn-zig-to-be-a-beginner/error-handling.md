---
title: "エラー型"
free: true
---

# エラー型

つづいてZigのエラー型についてみていきます。
C言語では `errno` のセットや、 コメントで｢NULLの場合はエラー｣だと書かれていて、プログラマが気をつけていく、
というようにエラーハンドリングが行われますが、
Zigでは型でエラーを表現することができます。
イメージとしては、Rustの `Result<T, U>` の、 `U` がエラーに制限されたものですね。

## 基本

以下のサンプルでは、メモリアロケータがメモリ割当に失敗した場合を考慮したプログラムです。
ここで、`catch |error|` という構文が出ていますが、
`allocator.alloc()` が `std.mem.Allocator.Error![]T` という形を返す点に注目です。

Rustの `Result<T, U>` 同様、`E!T` という型はそのまま値を取り出すことができず、

- `try` (Rustの `?` 演算子のようなイメージ)
- `catch` 構文を利用する(Rustの `let ~ else` のようなイメージ)

などを経由する必要があります。

```zig
const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 0 }){};
    const allocator = gpa.allocator();
    const values = allocator.alloc(i32, 1) catch |err| {
        std.debug.panic("failed to allocate i32: {}", .{err});
    };
    defer allocator.free(values);

    var value = values[0];
    value = 42;
    std.debug.print("value={}", .{value});
}
```

このような仕組みにより、Zigプログラム上でエラーを安全に表現することができるようになります。

## anyerror

まずは、基本的な `anyerror` について見ていきます。
これは、すべてのエラーを包含する集合のような型です。
例えば、 `std.mem.Allocator.Error` のようなエラー型も、この `anyerror` に含まれます。
実際、 `std.mem.Allcator.Error!T` のような戻り値に対して、 `anyerror!T` と表現しても動作します。

一方で、 `anyerror` はそれぞれのエラー特有の情報を隠してしまい、コードを読みづらくする危険があるので、
使用は最小限にとどめるのが良いと思います。

## カスタムエラー

もちろん、自分で新しくエラーを定義することができます。
ここで、エラーの場合はそのままチェックできている点に注目します。
Rustでは完全な値のラッピングが行われていますが、
Zigの`E!T`は組み込まれた型機能であるため、このようになっています。

```zig
const std = @import("std");

const E = error{
    A,
    B,
    C,
};

fn f(x: i32) E!void {
    return switch (x) {
        1 => E.A,
        2 => E.B,
        3 => E.C,
        else => {},
    };
}

test "test" {
    try std.testing.expect(f(1) == E.A);
    try std.testing.expect(f(2) == E.B);
    try std.testing.expect(f(3) == E.C);
    try std.testing.expect(try f(5) == {});
}
```

## エラー型の合成

`anyerror` を極力使わないと言っても、関数内で複数のエラー型を扱うことが避けられないかもしれません。
このような状況では、エラー型を合成する機能が役立ちます。

```zig
const std = @import("std");

const E1 = error{
    A,
};

const E2 = error{
    B,
};

const E = E1 || E2;

fn f(x: i32) E!void {
    return switch (x) {
        1 => E1.A,
        2 => E2.B,
        else => {},
    };
}

test "test" {
    try std.testing.expect(f(1) == E1.A);
    try std.testing.expect(f(2) == E2.B);
    try std.testing.expect(try f(5) == {});
}
```

