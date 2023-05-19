---
title: "defer"
free: true
---

# defer

つづいてdefer文です。
Goで馴染みのあるdeferですが、挙動が異なるので注意です。

Goのdeferはあくまでも｢関数ブロックを抜ける際｣に、逆順で実行される挙動です。

```go
package main

import (
	"fmt"
)

func main() {
	{
		fmt.Println("block1 start")
		defer fmt.Println("block1 end1")
		defer fmt.Println("block1 end2")
	}

	{
		fmt.Println("block2 start")
		defer fmt.Println("block2 end1")
		defer fmt.Println("block2 end2")
	}

}

```

```shell
$ go run sample.go
block1 start
block2 start
block2 end2
block2 end1
block1 end2
block1 end1
```

一方Zigは、ブロックスコープを抜ける際に実行されます。

```zig
const std = @import("std");

pub fn main() void {
    {
        std.debug.print("block1 start\n", .{});
        defer std.debug.print("block1 end1\n", .{});
        defer std.debug.print("block1 end2\n", .{});
    }

    {
        std.debug.print("block2 start\n", .{});
        defer std.debug.print("block2 end1\n", .{});
        defer std.debug.print("block2 end2\n", .{});
    }
}
```

```shell
$ zig run sample.zig
block1 start
block1 end2
block1 end1
block2 start
block2 end2
block2 end1
```

また、Goのdeferはあくまでも関数呼び出しに使いますが、Zigはいかなる文を利用することもできます。

> ```plain-text
> # *** Block Level ***
> Statement
>     <- KEYWORD_comptime? VarDecl
>      / KEYWORD_comptime BlockExprStatement
>      / KEYWORD_nosuspend BlockExprStatement
>      / KEYWORD_suspend BlockExprStatement
>      / KEYWORD_defer BlockExprStatement
>      / KEYWORD_errdefer Payload? BlockExprStatement
>      / IfStatement
>      / LabeledStatement
>      / SwitchExpr
>      / AssignExpr SEMICOLON
> ```
>
> <https://ziglang.org/documentation/0.10.1/#Grammar> より引用

## errdefer

errdeferについて見ていきます。
これは、スコープがエラーを返す場合に使えるものです。
実例を見てみましょう。

```zig
const std = @import("std");

pub fn main() !void {
    try f1();
    try f2();
}

fn f1() !void {
    // defer/errdeferはブロックを使うこともできる
    errdefer {
        std.debug.print("f1 returns error\n", .{});
    }

    return;
}

fn f2() !void {
    // エラーをキャッチすることもできる
    errdefer |err| {
        std.debug.print("f2 returns error {s}\n", .{@errorName(err)});
    }

    return error.DeferError;
}
```

実行してみると、`f1`の出力がされないことがわかります。

```shell
$ zig run sample.zig
f2 returns error DeferError
error: DeferError
# 省略
```

