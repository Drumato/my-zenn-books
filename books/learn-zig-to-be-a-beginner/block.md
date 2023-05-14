---
title: "Zig構文解説-block-"
free: true
---

# Zig構文解説-block-

ここまでは型システムを概観してきましたが、
ここからはZigの構文について紹介します。
まずはブロック構文です。
以下のサンプルを見てください。

```zig
const std = @import("std");

test "test" {
    const v1 = @as(i32, 42);

    const v2 = v2_block: {
        break :v2_block v1 + 1;
    };

    try std.testing.expectEqual(42, v1);
    try std.testing.expect(v2 == 43);
}

```

このサンプルは、ブロックを式として使っていることを示しています。
これは、Rustでも見られる仕組みです。

```rust
pub fn main() {
    let v1 = 42i32;
    let v2 = {
        v1 + 1
    };
    eprintln!("{}, {}", v1, v2);
}
```

それぞれのブロックにはラベルをつけることができます。

## ブロックスコープ

ブロックごとに新たなスコープを作成するため、
ブロックの外部で内部の変数を参照することはできません。

ここで、前の章で紹介したシャドウイングの概念が気になる人もいるかもしれません。
例えば、Rustでは以下のようなコードはvalidです。

```rust
pub fn main() {
    let x = 42i32;
    {
        let x = x + 1;
        eprintln!("{}", x);
    }
}
```

一方、Zigではこのようなことはできません。
レキシカルスコープの概念で、重複する識別子の宣言を検出し、コンパイルエラーを出力します。

