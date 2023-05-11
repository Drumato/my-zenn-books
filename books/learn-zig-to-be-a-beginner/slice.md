---
title: "スライス型/文字列型"
free: true
---

# スライス型/文字列型

続いてZigのスライス型について解説します。
これはある配列の参照であり、要素数とポインタが保持されたデータ型です。
これも、Rustのスライスとほぼ同様に考えることができます。

また、Zigで文字列は `[]const u8` のような型ですが、
これはまさしく `u8` のスライスです。
なので、この章で文字列についても扱うことにします。

## 基本的なスライスの機能

ある配列を用意し、その配列を参照するすることで、スライスを得ることができます。
配列を`[start..end]` はスライス演算子として定義されており、
基底となる配列を半開区間で切り出して参照します。

なお、スタート位置の変数を `var` にしている理由については後述します。

```zig
const std = @import("std");

test "test" {
    const arr = [_]i32{ 1, 2, 3, 4, 5 };

    var start_known_at_runtime: usize = 0;
    const s = arr[start_known_at_runtime..arr.len];

    try std.testing.expectEqual([]const i32, @TypeOf(s));
    try std.testing.expect(s.len == 5);
    try std.testing.expect(s[2] == 3);
}
```

### `*[N]T` と `[]T` の違い

先程スライス演算子の始点として、`var` を利用していましたが、
これはZigのある特徴を説明するために、あえてそのようにしていました。

Zigでは、スライスの長さがコンパイル時にわかっていると、
単なるスライスではなく、 `*[N]T` という、配列を指すポインタとして扱われます。
このようになるメリットとして、コンパイル時に範囲外のアクセスを検知できる場合に、Zigコンパイラが教えてくれるというものがあります。

```zig
const std = @import("std");

test "test" {
    const arr = [_]i32{ 1, 2, 3, 4, 5 };

    const start_known_at_comptime: usize = 0;
    const s = arr[start_known_at_comptime..arr.len];

    try std.testing.expectEqual(*const [5]i32, @TypeOf(s));
    try std.testing.expect(s.len == 5);
    try std.testing.expect(s[2] == 3);

    // error: index 5 outside array of length 5
    _ = s[5];
}
```

この挙動からも、Zigがコンパイル時計算/解析を非常に大切にしていることがわかります。
このように、同じ構文で異なるセマンティクスを持つ言語は他にもあります。
例えば、Rustのムーブセマンティクスとコピーセマンティクスが代表例だと思います。

｢スライスが配列の参照｣だという説明でピンときた人も多いかもしれませんが、
ポインタのときと同じように、参照先が可変なのかどうかで挙動が変化します。
下の例では取り上げませんが、
もちろん、スライスを代入した変数自体が `var` で宣言されていると、
どの配列を参照するかを変更することができる点に注意してください。

```zig
const std = @import("std");

test "test" {
    var arr1 = [_]i32{1};
    var start: usize = 0;
    var s1 = arr1[start..arr1.len];

    s1[0] = 42;
    try std.testing.expectEqual([]i32, @TypeOf(s1));
    try std.testing.expect(arr1[0] == 42);

    const arr2 = [_]i32{1};
    var s2 = arr2[start..arr2.len];

    try std.testing.expectEqual([]const i32, @TypeOf(s2));
    // error: cannot assign to constant
    s2[0] = 42;
}
```

## 文字列

## 参考文献

- <https://ziglang.org/documentation/0.10.1/#Slices>

