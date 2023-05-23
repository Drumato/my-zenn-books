---
title: "標準ライブラリ解説-std.EnumSet-"
free: true
---

# 標準ライブラリ解説-std.EnumSet-

よく使われそうな標準ライブラリ第二弾、 `std.EnumSet`です。
関数名から想像できるように、enumのヴァリアントを元とする集合を管理するためのデータ構造です。

## 基本的な使い方

集合が取り扱うenumを渡して初期化します。

```zig
const std = @import("std");

const E = enum {
    a,
    b,
    c,
    d,
    e,
};

test "test" {
    var set = std.EnumSet(E){};
    try std.testing.expect(!set.contains(.a));

    set.insert(.a);
    try std.testing.expect(set.contains(.a));

    var it = set.iterator();
    try std.testing.expect(it.next().? == .a);
    try std.testing.expect(it.next() == null);
}
```

## `initFull()`

enumのヴァリアントがすべて含まれた集合を得ることができます。

```zig
const std = @import("std");

const E = enum {
    a,
    b,
    c,
    d,
    e,
};

test "test" {
    var set = std.EnumSet(E).initFull();
    try std.testing.expect(set.count() == 5);
}
```

## `setUnion()/setIntersection()`

2つの `EnumSet` の和/積を取って、メソッドのレシーバをinplaceに更新します。

```zig
const std = @import("std");

const E = enum {
    a,
    b,
    c,
    d,
    e,
};

test "setUnion" {
    var s1 = std.EnumSet(E){};
    s1.insert(.a);
    var s2 = std.EnumSet(E){};
    s2.insert(.b);
    s2.insert(.c);

    s1.setUnion(s2);
    try std.testing.expect(s1.count() == 3);
    try std.testing.expect(s1.contains(.a));
    try std.testing.expect(s1.contains(.b));
    try std.testing.expect(s1.contains(.c));
}

test "setIntersection" {
    var s1 = std.EnumSet(E){};
    s1.insert(.a);
    s1.insert(.b);
    var s2 = std.EnumSet(E){};
    s2.insert(.a);
    s2.insert(.c);

    s1.setIntersection(s2);
    try std.testing.expect(s1.count() == 1);
    try std.testing.expect(s1.contains(.a));
    try std.testing.expect(!s1.contains(.b));
    try std.testing.expect(!s1.contains(.c));
}
```

## 参考文献

- <https://ziglang.org/documentation/0.10.1/std/#root;EnumSet>

