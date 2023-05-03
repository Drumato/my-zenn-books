---
title: "プリミティブ型"
free: true
---

# プリミティブ型

ここからは、実際にZigのプログラミングについて学んでいきます。
Zigでは、以下の型がプリミティブ型として定義されています。
ここで、`c_` から始まる型以外にも、
例えば `isize` は `intptr_t` 、 `f64` は `double` と、
C言語と互換性を持つように設計されている点に注意です。

- 符号付き整数
  - `i<N>`
  - `isize`
- 非符号付き整数
  - `u<N>`
  - `usize`
- 浮動小数点数
  - `f16`
  - `f32`
  - `f64`
  - `f80`
  - `f128`
- C言語とABIレベルで互換性を持つために用意された形
  - `c_short`
  - `c_ushort`
  - `c_int`
  - `c_uint`
  - `c_long`
  - `c_ulong`
  - `c_longlong`
  - `c_ulonglong`
  - `c_longdouble`
- その他
  - `bool`
  - `anyopaque`
  - `void`
  - `noreturn`
  - `type`
  - `anyerror`
  - `comptime_int`
  - `comptime_float`

次の章から、カテゴリごとに解説していきます。

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Primitive-Types>

