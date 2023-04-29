---
title: "はじめに"
free: true
---

この本は、他によく使うプログラミング言語があるものの、
Zigに興味を持ち、使ってみたいと思っている方向けに、
素早く最低限の機能をキャッチアップすることを目的に書かれています。

Zigを学ぶ上で最も参考になるのは、間違いなく **[公式ドキュメント](https://ziglang.org/documentation/0.10.1/)** です。
言語機能についてとても詳しく解説されていますし、 **[Zig Standard Library](https://ziglang.org/documentation/master/std/#A;std)** もとても役立ちます。
英語を読むことが苦でない人は、このドキュメントを一通り読むだけで、すぐに使えるようになるでしょう。
一方で、Zigは(あくまで個人的に、ですが)独特な言語だと思っていて、人によっては理解するのに苦労するかもしれません。

そこで、本書では、(私が知っている)他のプログラミング言語と対比したり、
Zigの理解をサポートするための補足情報を適宜混ぜながら、
より簡易にZigを使い始められるように説明していきます。
この本によって、Zigに興味を持ってくださる方が一人でも増えれば幸いです。

本書全体を通して、他のプログラミングと比較する場合には、順位や良し悪しについては触れず、
単に **"言語仕様･機能の違い"** としてのみ説明することにします。

本書で取り上げるプログラミング言語を以下に挙げます。

- C言語
- Rust
- Go

なお、本書で扱うZigのバージョンは0.10.1とします。

## 対象読者

- 何らかのプログラミング言語を触ったことがある
- Zigに興味を持っている

## Zigとは

まずは、Zigという言語がどのような特徴を持っているのか、
公式ドキュメントの内容をベースに紹介します。

### Robustness

Zigの大きな特徴に、 **プログラムの挙動が安定的であり、コントロール可能** というものがあります。
公式ドキュメントでは、以下のように述べられています。

> **Robust**
> Behavior is correct even for edge cases such as out of memory.
>
> <https://ziglang.org/documentation/0.10.1/#toc-Introduction> より引用

いくつか具体的な例を見てみましょう。
現時点では細かい文法や機能の解説はしないので、雰囲気だけ感じ取っていただければと思います。
まずは、固定長の配列にアクセスするプログラムです。
以下のプログラムをコンパイルしようとすると、コンパイルエラーが出力されます。

```zig
pub fn main() void {
    const a1: [5]u8 = [_]u8{1, 2, 3, 4, 5};

    // will detect at compile-time
    const index_out_of_bounds = a1[5];
    std.debug.print("{}\n", .{index_out_of_bounds});
}
```

```shell
$ zig build-exe z.zig
z.zig:7:36: error: index 5 outside array of length 5
    const index_out_of_bounds = a1[5];
                                   ^
referenced by:
    callMain: /home/drumato/.zig/lib/std/start.zig:604:17
    initEventLoopAndCallMain: /home/drumato/.zig/lib/std/start.zig:548:51
    remaining reference traces hidden; use '-freference-trace' to see all reference traces
```

また、コンパイル時に検知不可能なものに対しても、実行時パニックによって異常終了します。

```zig
const std = @import("std");

pub fn main() void {
    const a1: [5]u8 = [_]u8{1, 2, 3, 4, 5};
    foo(&a1);
}

fn foo(s1: []const u8) void {
    // will detect at runtime
    const index_out_of_bounds = s1[5];
    std.debug.print("{}\n", .{index_out_of_bounds});
}
```

```shell
$ zig build-exe sample.zig
$ ./sample
thread 30792 panic: index out of bounds: index 5, len 5                                                                                                                                       
./sample.zig:10:35: 0x211e4a in foo (sample)                                                                                                                                                            
    const index_out_of_bounds = s1[5];                                                                                                                                                        
                                  ^                                                                                                                                                           
./sample.zig:5:8: 0x2102d0 in main (sample)                                                                                                                                                             
    foo(&a1);                                                                                                                                                                                 
       ^                                                                                                                                                                                      
/home/drumato/.zig/lib/std/start.zig:604:22: 0x20f84c in posixCallMainAndExit (sample)                                                                                                             
            root.main();                                                                                                                                                                      
                     ^                                                                                                                                                                        
/home/drumato/.zig/lib/std/start.zig:376:5: 0x20f351 in _start (sample)                                                                                                                            
    @call(.{ .modifier = .never_inline }, posixCallMainAndExit, .{});                                                                                                                         
    ^                                                                                                                                                                                         
```

これは、RustやGoのようなプログラミング言語でも見られる挙動です。

```rust
// Rustの場合
pub fn main() {
    let x: [u8; 5] = [1, 2, 3, 4, 5];
    // error: this operation will panic at runtime    
    //        index out of bounds: the length is 5 but the index is 5                                                                                                          
    eprintln!("{}", x[5]);

    f(&x);
}

fn f(s: &[u8]) {
    // thread 'main' panicked at 'index out of bounds: the len is 5 but the index is 5'
    eprintln!("{}", s[5]);
}
```

```go
// Goの場合
package main

import "fmt"

func main() {
        a := [5]uint8{1, 2, 3, 4, 5}
        // ./sample.go:8:16: invalid argument: index 5 out of bounds [0:5]
        fmt.Println(a[5])

        f(a[0:])
}

func f(a []uint8) {
        // panic: runtime error: index out of range [5] with length 5
        fmt.Println(a[5])
}
```

一方、(Zigの背景的に)Zigとよく比較されるC言語では、(どちらがいいのか、という話は抜きにして)このような実行時チェックが行われません。
これは、Zigが比較的リッチなランタイム(条件付き、詳しくは後述)を持っていることを意味します。

```c
#include <stdio.h>

void f(int *a) {
    // 配列の範囲外が参照され、普通に値が出力される
    printf("%d\n", a[10]);
}

int main() {
    int a[5] = {1, 2, 3, 4, 5};
    // gcc 11.3.0では、 -Wall -Wextraをつけても警告されない
    printf("%d\n", a[10]);

    f(a);
}
```

次に、型システムについて紹介します。
Zigは強い静的型システムを持ち、それによってプログラムの挙動をコントロールすることができます。
以下のプログラムでは、8bit非符号付き整数を表す `u8` が持つ値の範囲をコンパイル時にチェックされ、
large2をsmall2に代入する部分でコンパイルエラーが出力されます。

```zig
const std = @import("std");

pub fn main() void {
    const large1: u64 = 255;
    const small1: u8 = large1;
    _ = small1;

    const large2: u64 = 256;
    const small2: u8 = large2;
    // error: type 'u8' cannot represent integer value '256'
    _ = small2;
}
```

