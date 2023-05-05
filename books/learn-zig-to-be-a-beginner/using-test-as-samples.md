---
title: "本書で使用するテスト機能について"
free: true
---

# サンプルコードで利用するtestについて

本書全体を通して、Zigのサンプルコードでは組み込みテスト機能を利用します。
詳しくはテストの章で詳しく扱うものとして、
ここではかんたんな解説を行っておきます。

Zigは、テスト機能が言語機能自体に組み込まれています。
(全く同じ構造、というわけではないですが)、テストがネイティブに利用できるという意味では、GoやRustとほぼ同様の開発体験を持っている、と言っても差し支えないでしょう。

例えば、以下のようなコードを動かしてみます。
これは、`std.ArrayList(i32)` に正しく要素が追加されたかをテストしています。

```zig
const std = @import("std");

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    // 以下のdefer文をコメントアウトすると、
    // std.testing.allocatorがメモリが開放されていないことを検知してくれる
    defer list.deinit(); 

    const src = [_]i32{ 1, 2, 3, 4 };
    try list.appendSlice(&src);
    try std.testing.expectEqualSlices(i32, list.items, &src);
}
```

`zig test main.zig` のようにしてみると、このテストが通ることがわかります。

```shell
$ zig test src/main.zig
All 1 tests passed.
```

`std.testing` はテストに便利な機能を多数提供してくれています。
例えば、コメントに書いてあるとおり、 `list.deinit()` の行をコメントアウトします。
このメソッドは、`std.ArrayList` が自身の持つメモリ領域を開放します。
これを実行しないように書き換えて `zig test` を実行すると、メモリリークを検知します。

```shell
$ zig test dont-deinit.zig
Test [1/1] test.simple test... [gpa] (err): memory address 0xffff9c337000 leaked:
/usr/local/zig/lib/std/array_list.zig:403:67: 0x2398f7 in ensureTotalCapacityPrecise (test)
                const new_memory = try self.allocator.alignedAlloc(T, alignment, new_capacity);
                                                                  ^
/usr/local/zig/lib/std/array_list.zig:379:51: 0x2275bf in ensureTotalCapacity (test)
            return self.ensureTotalCapacityPrecise(better_capacity);
                                                  ^
/usr/local/zig/lib/std/array_list.zig:414:60: 0x223b07 in ensureUnusedCapacity (test)
            return self.ensureTotalCapacity(self.items.len + additional_count);
                                                           ^
/usr/local/zig/lib/std/array_list.zig:252:48: 0x21fad7 in appendSlice (test)
            try self.ensureUnusedCapacity(items.len);
                                               ^
/home/drumato/tmp/zig/src/main.zig:8:25: 0x21f9d7 in test.simple test (test)
    try list.appendSlice(&src);
                        ^
/usr/local/zig/lib/test_runner.zig:177:28: 0x233aa7 in mainTerminal (test)
        } else test_fn.func();
                           ^
/usr/local/zig/lib/test_runner.zig:37:28: 0x225933 in main (test)
        return mainTerminal();
                           ^
/usr/local/zig/lib/std/start.zig:599:22: 0x2203bb in posixCallMainAndExit (test)
            root.main();
                     ^


All 1 tests passed.
1 errors were logged.
1 tests leaked memory.
error: the following test command failed with exit code 1:
/home/drumato/tmp/zig/zig-cache/o/a3a1e7e721b1d236ff3daf4dcef49883/test
```

Zigの挙動を理解するために小さなコード片を動かしていきますが、
この組み込みテスト機能が便利なので、本書ではこれを利用します。
この方式は公式ドキュメントでも利用されていて、
公式ドキュメントの説明はほとんど組み込みテスト機能を利用しています。

