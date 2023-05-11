---
title: "Optional型"
free: true
---

# Optional型

RustでOptionやTypeScriptでオブジェクトのプロパティを `foo?: number;` のようにできるのと同じように、
Null安全な型を定義することができます。

型定義の文法としては、以下を見るとなんとなくイメージがつかめると思います。

> ```plain-text
> TypeExpr <- PrefixTypeOp* ErrorUnionExpr
> 
> PrefixTypeOp
>     <- QUESTIONMARK
>      / KEYWORD_anyframe MINUSRARROW
>      / SliceTypeStart (ByteAlign / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
>      / PtrTypeStart (KEYWORD_align LPAREN Expr (COLON INTEGER COLON INTEGER)? RPAREN / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
>      / ArrayTypeStart
> 
> ErrorUnionExpr <- SuffixExpr (EXCLAMATIONMARK TypeExpr)?
> 
> SuffixExpr
>     <- KEYWORD_async PrimaryTypeExpr SuffixOp* FnCallArguments
>      / PrimaryTypeExpr (SuffixOp / FnCallArguments)*
> 
> PrimaryTypeExpr
>     <- BUILTINIDENTIFIER FnCallArguments
>      / CHAR_LITERAL
>      / ContainerDecl
>      / DOT IDENTIFIER
>      / DOT InitList
>      / ErrorSetDecl
>      / FLOAT
>      / FnProto
>      / GroupedExpr
>      / LabeledTypeExpr
>      / IDENTIFIER
>      / IfTypeExpr
>      / INTEGER
>      / KEYWORD_comptime TypeExpr
>      / KEYWORD_error DOT IDENTIFIER
>      / KEYWORD_anyframe
>      / KEYWORD_unreachable
>      / STRINGLITERAL
>      / SwitchExpr
> ```

早速実例を見てみましょう。

```zig
const std = @import("std");

test "test" {
    const v1: ?i32 = 42;
    // Rustの.unwrap()と同等
    try std.testing.expect(v1.? == 42);

    // Rustのif let Some(v1_inner) = v1 {} のように、
    // panicさせず値にアクセスすることができる
    if (v1) |v1_inner| {
        try std.testing.expectEqual(i32, @TypeOf(v1_inner));
        try std.testing.expect(v1_inner == 42);
    } else {
        unreachable;
    }

    const v2: ?i32 = null;
    // nullと比較可能
    try std.testing.expect(v2 == null);
}
```

このように、ある値を持っているかもしれない、という状態を型で表現することで、安全に扱うことができます。
C言語では、以下のようないわゆるNULLチェックを利用して同様のことを行いますが、NULLチェックを怠った場合に意図しない挙動を起こす心配があります。

```c
#include <stdio.h>

int main(void) {
  const int base_int = 42;
  const int *v1 = &base_int;

  // このNULLチェックを忘れるとnull pointer dereferenceとなる
  if (v1 != NULL) {
    printf("%d\n", *v1);
  }
}
```

## `orelse`

`orelse` 演算子は、デフォルト値を設定したり、早期リターンをきれいに書くために使われます。

```zig
const std = @import("std");

fn f1(v: ?i32) i32 {
    return v orelse 42;
}

fn f2(v: ?i32) i32 {
    const v2 = v orelse return 42;

    return v2 + 1;
}

test "test" {
    try std.testing.expect(f1(30) == 30);
    try std.testing.expect(f1(null) == 42);

    try std.testing.expect(f2(30) == 31);
    try std.testing.expect(f2(null) == 42);
}
```

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Optionals>

