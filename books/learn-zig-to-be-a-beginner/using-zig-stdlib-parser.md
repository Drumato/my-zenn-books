---
title: "標準ライブラリのZigパーサを使ってみよう"
free: true
---

# 標準ライブラリのZigパーサを使ってみよう

ここからは、Zigプログラミングを実践してみましょう。
今回は、 `@import("std").zig` にある、標準のZigパーサを使って遊んでみたいと思います。
このパッケージはZigコンパイラそのものからも、zls(Zig公式のLSP)でも利用されているものなので、仕様追従されているものとして利用できます。

まずは以下のコマンドを実行して、新しくZigプロジェクトを作成します。

```shell
$ mkdir sample && cd sample
$ zig init-exe
```

本章の完成品は以下のリポジトリにおいてありますので、よかったら参考にしてください。

<https://github.com/Drumato/my-zenn-books/tree/main/books/learn-zig-to-be-a-beginner/using-zig-stdlib-parser>

## コマンドライン引数の読み込み

まずは、パーサが読み込むZigプログラムのファイルパスを受け取れるようにします。
ここではコマンドライン引数を利用する例を紹介します。
C言語では、main関数に渡される`int argc/char **argv` を利用しますが、
Zigでは標準ライブラリの関数を利用して取得します。

<https://ziglang.org/documentation/0.10.1/std/#A;std:process>

汎用的なAPIとしては `std.process.ArgIterator` がありますが、
ここでは引数の数をみたいので、 `std.process.ArgIteratorPosix` を利用します。
名前の通りイテレータの機能を提供しているので、
各引数にアクセスするために `next()` を呼び出しています。

```zig
// src/main.zig

const std = @import("std");
const debug = std.debug;
const process = std.process;

pub fn main() !void {
    var args = process.ArgIteratorPosix.init();

    if (args.count < 2) {
        debug.print("usage: using-zig-stdlib-parser <zig-file>", .{});
        process.exit(1);
    }

    debug.assert(args.next() != null);
    const relative_filepath = args.next().?;
    _ = relative_filepath;
}
```

このアプローチは、Rustのものに非常に近いです。
Rustでは `std::env::Args` が `Iterator<Item=String>` や `ExactSizeIterator<Item=String>` を実装しています。

<https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=2e806d936d7d7c09f3866f0d0aae1179>

```rust
fn main() {
    let mut args = std::env::args();
    
    if args.len() < 2 {
        eprintln!("usage: using-zig-stdlib-parser <zig-file>");
        std::process::exit(1);
    }
    
    assert!(args.next().is_some());
    let _filepath = args.next().unwrap();
    
}
```

## ファイルの読み込み

ファイルパスが取得できたので、実際にファイルを読み込みます。
ファイル関連の操作は、 `@import("std").fs` に定義されています。

<https://ziglang.org/documentation/0.10.1/std/#A;std:fs>

開いたファイルの中身を読み込む際、Zigでは主に2つの選択肢が用意されています。

- メモリアロケータを利用せず、一定サイズのみ読み込める方法
- メモリアロケータを利用して、可変サイズを読み込める方法

今回は後者を使って読み込むことにしますが、
ミニマルなフットプリントで動かすかどうかが、
ユーザに託されているのがZigの特徴だという点に注目しておきましょう。

ファイルを読み込むように変更したコードを以下に示します。
今回は、メモリアロケータとして `std.heap.GeneralPurposeAllocator` を利用しました。
これはクロスプラットフォームで利用でき、メモリリークを検出してくれたり(オプションで無効化できます)、ダブルフリーの検出もできる、汎用的なものです。

```zig
// src/main.zig

const std = @import("std");
const debug = std.debug;
const process = std.process;
const fs = std.fs;

pub fn main() !void {
    // 省略
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 0 }){};
    const allocator = gpa.allocator();

    const zig_source = try file.readToEndAllocOptions(allocator, 4096, 4096, @alignOf(u8), 0);
    defer allocator.free(zig_source);

    std.debug.print("{s}\n", .{zig_source});
}
```

```shell
$ zig build
$ ./zig-out/bin/sample sample.zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"world"});
}
```

## ASTへの変換と操作

無事ファイルが読みこめたので、いよいよZigパーサに引き渡して、ASTに変換します。
`@import("std").zig` で関連するAPIが提供されています。

<https://ziglang.org/documentation/0.10.1/std/#A;std:zig>

ここで、 `zig.parse()` という関数を利用してASTに変換します。

```zig
// src/main.zig

const std = @import("std");
const debug = std.debug;
const process = std.process;
const fs = std.fs;
const zig = std.zig;

pub fn main() !void {
    // 省略
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 0 }){};
    const allocator = gpa.allocator();

    const zig_source = try file.readToEndAllocOptions(allocator, 4096, 4096, @alignOf(u8), 0);
    defer allocator.free(zig_source);

    var tree = try zig.parse(allocator, zig_source);
    defer tree.deinit(allocator);
}
```

`std.zig` ではすべてのASTノードに対して `std.zig.Ast.Node.Index` というインデックスが割り当てられていて、
そのindexを使って各ノードにアクセスする必要があります。
また、あるツリーにぶら下がったノードのリストは `std.MultiArrayList(T)` という、少し複雑なデータ構造で管理されています。
これは、例えば `std.MultiArrayList(StructA)` であれば、 `StructA` のフィールドでフィルタしたリストを取得できるような多次元リストとなっています。
これらを扱うとかなり複雑なプログラムとなってしまうので、ここではあるファイルのルートにある宣言の一覧を表示する程度にとどめておくことにします。
`std.zig` のASTを詳しく扱いたい場合、以下のソースコードがとても参考になります。

<https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/zig/render.zig#L16>

これは、`std.zig.Ast.render()` というライブラリ関数の内部実装になっていて、
ASTを再帰的に探索しつつ、その表現をフォーマットした文字列に変換するものです。
本書でも、このライブラリをコードリーディングする章を設けていますので、よかったら参考にしてください。

話を戻します。
以前の章で触れたように、Zigのソースファイルは、それ自体がコンテナの宣言として扱われます。
これは、Zigの構文規則を見てみるとすぐに理解することができます。

> `Root <- skip container_doc_comment? ContainerMembers eof`
>
> <https://ziglang.org/documentation/0.10.1/#Grammar> より引用

例えば `std.zig.Ast` は構造体型のように扱えますが、
定義ファイルを探してみると、ファイルのトップレベルにメンバ定義が書かれていることがわかります。

<https://github.com/ziglang/zig/blob/0.10.1/lib/std/zig/Ast.zig>

```zig
//! Abstract Syntax Tree for Zig source code.

/// Reference to externally-owned data.
source: [:0]const u8,

tokens: TokenList.Slice,
/// The root AST node is assumed to be index 0. Since there can be no
/// references to the root node, this means 0 is available to indicate null.
nodes: NodeList.Slice,
extra_data: []Node.Index,

// 省略
```

このことから、あるファイルをパースしたとき、そのトップレベルの宣言は、ファイルをコンテナとして見たときのメンバ宣言だと考えることができます。

では実際にこれらを出力してみましょう。
トップレベルの宣言をイテレーションして出力するコードを追加します。

出力先は標準出力とするため、新たに標準出力の書き出し先を用意しています。
ちなみに、 `std.debug.print()` は標準エラー出力に対するunbuffered-I/Oを行うものです。
これはAPIドキュメントに詳しく記載されています。

<https://ziglang.org/documentation/0.10.1/std/#root;debug.print>

実装を読んでみてもわかりやすいと思います。

<https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/debug.zig#LL87C1-L95C1>

```zig
// src/main.zig

const std = @import("std");
const debug = std.debug;
const process = std.process;
const fs = std.fs;
const zig = std.zig;

pub fn main() !void {
    // 省略

    const stdout = std.io.getStdOut().writer();
    for (tree.rootDecls()) |root_decl_index, i| {
        try stdout.print("root decls[{}]: {s}\n", .{ i, tree.getNodeSource(root_decl_index) });
    }
}
```

実際に実行してみると、トップレベルの宣言単位で見たときの、セミコロン等が省略されているのが確認できると思います。
生のソースコード表現を取得したい場合は、変わりに `tree.render(allocator)` を利用できます。

```shell
$ zig build
$ ./zig-out/bin/sample sample.zig
root decls[0]: const std = @import("std")
root decls[1]: pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"world"});
}
```

