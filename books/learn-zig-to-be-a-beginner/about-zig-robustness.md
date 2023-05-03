---
title: "Zigの特徴-Robustness-"
free: true
---

# Zigの特徴-Robustness-

Zigの大きな特徴に、 **プログラムの挙動が安定的であり、コントロール可能な堅牢性を持つ** というものがあります。
いくつか具体的な例を見てみましょう。
現時点では細かい文法や機能の解説はしないので、雰囲気だけ感じ取っていただければと思います。

## 配列の範囲外にアクセスする

まずは、固定長の配列にアクセスするプログラムです。
以下のプログラムをコンパイルしようとすると、コンパイルエラーが出力されます。

```zig
const std = @import("std");

pub fn main() void {
    const a1: [5]u8 = [_]u8{ 1, 2, 3, 4, 5 };

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
    const a1: [5]u8 = [_]u8{ 1, 2, 3, 4, 5 };
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

Zigは、公式ドキュメントにも以下のような記載があるようにC言語およびC++を意識しています。

> ⚡ Maintain it with Zig
> Incrementally improve your C/C++/Zig codebase.
>   Use Zig as a zero-dependency, drop-in C/C++ compiler that supports cross-compilation out-of-the-box.
>   Leverage zig build to create a consistent development environment across all platforms.
>   Add a Zig compilation unit to C/C++ projects; cross-language LTO is enabled by default.
> 
> <https://ziglang.org/> より引用

つまり、C言語やC++を採用している、システムプログラミング領域のプロジェクトでも使えるような言語として開発されていますが、
一方で、コンパイル字や実行時チェックの恩恵を受けることができるのです。
ご存知のように、C言語で同様のことを行うと、実行時チェックは行われません。

```c
#include <stdio.h>

void f(int *a) {
    // 配列の範囲外が参照され、普通に値が出力される
    printf("%d\n", a[10]);
}

int main() {
    int a[5] = {1, 2, 3, 4, 5};
    // gcc 11.3.0では、 -Wall -Wextraをつけても警告されない
    // clangd 14.0.0では警告されるのを確認した
    printf("%d\n", a[10]);

    f(a);
}
```

## 堅牢な型システム

次に、型システムについて紹介します。
Zigは強い静的型システムを持ち、それによってプログラムの挙動をコントロールすることができます。
以下のプログラムでは、8bit非符号付き整数を表す `u8` が持つ値の範囲をコンパイル時にチェックされ、
large2をsmall2に代入する部分でコンパイルエラーが出力されます。

```zig
// コンパイル時チェックの例
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

```zig
// ランタイムチェックの例
const std = @import("std");

pub fn main() void {
    const large1: u64 = 255;
    f(large1);
}

fn f(v: u8) void {
    // panic: integer overflow
    std.debug.print("{}\n", .{v + 1});
}
```

```zig
// オーバーフローを考慮した、Zigらしいプログラム
const std = @import("std");

pub fn main() void {
    const large1: u64 = 254;
    const large2: u64 = 255;
    f(large1);
    f(large2);
}

fn f(v: u8) void {
    // std.math.addは error{Overflow}!Tという値を返す
    // T!Uという型と記法については後述
    // 今はRustのResultや、HaskellのEither｢っぽい｣ものと思ってOK
    const added = std.math.add(u8, v, 1) catch |err| {
        std.debug.panic("overflow detected; src={}, adder={}, err={}\n", .{ v, 1, err });
    };

    std.debug.print("{}\n", .{added});
}
```

一方、C言語ではオーバーフローし、0が入っていることがわかります。

```c
#include <stdio.h>
#include <stdint.h>

int main() {
    const uint64_t over_uint8_t = 256;
    // gcc 11.3.0では、 -Wall -Wextraをつけても警告されない
    // clangd 14.0.0では警告されるのを確認した
    const uint8_t dst = over_uint8_t;

    printf("%d", dst);
}
```

