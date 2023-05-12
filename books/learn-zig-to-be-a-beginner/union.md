---
title: "union"
free: true
---

# union

Cなどの言語を使ったことがない人には馴染みがない仕組みかもしれませんが、
あるメモリ空間を複数の型で共用するような型です。
これも実例を見てみたほうが早いので、C言語のサンプルを見てみましょう。

```c
#include <stdio.h>

union U {
  int i;
  _Bool b;
};

int main(void) {
  union U u;
  u.i = 0;

  printf("%d\n", u.i);
  printf("%s\n", u.b ? "true" : "false");

  u.i = 1;
  printf("%d\n", u.i);
  printf("%s\n", u.b ? "true" : "false");
}
```

```shell
$ gcc sample.c && ./a.out
0
false
1
true
```

ここでフィールド `i` を変更すると、 `b` からアクセスしたときの挙動も変化していることがわかります。

## 基本

Zigのunionも大まかにこのようなものですが、
違いとして、 `activating` という概念が導入されています。
先ほどのサンプルをZigで書き直そうとすると、実行時パニックが起きます。
ランタイムチェックによって、どのフィールドが使われているかを検知しているのがわかります。

```zig
const std = @import("std");

const U = union {
    i: u1,
    b: bool,
};

test "test" {
    var u = U{ .i = 0 };
    try std.testing.expect(u.i == 0);
    // panic: access of inactive union field
    try std.testing.expect(!u.b);

    u.i = 1;
    try std.testing.expect(u.i == 1);
    try std.testing.expect(u.b);
}
```

これを回避するには、以下のように全体で初期化しなおします。

```zig
const std = @import("std");

const U = union {
    i: u1,
    b: bool,
};

test "test" {
    var u = U{ .i = 0 };
    try std.testing.expect(u.i == 0);
    u = U{ .b = false };
    try std.testing.expect(!u.b);
}
```

## Tagged Union

一般にタグ付き共用体と呼ばれる機能です。
Zigではこれを利用して、Rustの `enum` と同等の機能を実現します。

```zig

const std = @import("std");

const NodeTag = enum {
    integer,
    addition,
};

const Node = union(NodeTag) {
    integer: isize,
    addition: Addition,

    const Addition = struct {
        left: *const Node,
        right: *const Node,
    };
};

test "test" {
    const n = Node{
        .addition = Node.Addition{
            .left = &Node{
                .integer = 1,
            },
            .right = &Node{
                .integer = 2,
            },
        },
    };

    try std.testing.expectEqual(Node, @TypeOf(n));
    try std.testing.expect(std.mem.eql(u8, "addition", @tagName(n)));

    switch (n) {
        .integer => |value| {
            try std.testing.expectEqual(isize, @TypeOf(value));
        },
        .addition => |addition| {
            try std.testing.expectEqual(*const Node, @TypeOf(addition.left));
            try std.testing.expectEqual(*const Node, @TypeOf(addition.right));
        },
    }
}
```

