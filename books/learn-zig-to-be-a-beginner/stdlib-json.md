---
title: "標準ライブラリ解説-std.json-"
free: true
---

# 標準ライブラリ解説-std.json-

ここからは、よく使われそうな標準ライブラリを解説していきます。
第一弾として、 `std.json` を見ていきましょう。
このライブラリは、JSONパーサやバリデータを提供しています。

Zigの標準ライブラリを理解するコツとしては、
<https://ziglang.org/documentation/0.10.1/std/#root> をよく読みに行くことと、
標準ライブラリの実装のうち、 `test {}` を見て挙動を理解することです。
たとえば、 `std.ArrayList(T)` の `insert()` メソッドであれば、以下のようなテストが用意されています。

<https://ziglang.org/documentation/0.10.1/std/src/array_list.zig.html#L1180>

## JSONのバリデーション

`std.json.validate()` を利用して、JSONのバリデーションを行ってみます。
まずは、以下のようなvalidなJSONを入力して、エラーが怒らないことを確認してみましょう。

```json
{
  "name": "learn-zig-to-be-a-beginner",
  "published": true,
  "publishedYear": 2023,
  "chapters": [
    {
      "name": "introduction",
      "index": 0
    },
    {
      "name": "main",
      "index": 1
    },
    {
      "name": "conclusion",
      "index": 2
    }
  ]
}
```

ファイルの読み込みには、 `@embedFile()` という組み込み関数を利用します。
これは、 `std.fs` などのパッケージとことなりコンパイル時に実行されるため、
コンパイル時に発見できないファイルが指定されているとコンパイルエラーを出力する代わりに、
エラーハンドリングを行わなくて良いという利点があります。

```zig
const std = @import("std");

test "test" {
    const json_file = @embedFile("sample.json");
    try std.testing.expect(std.json.validate(json_file));
}
```

```shell
$ zig test src/main.zig
All 1 tests passed.
```

次に、sample.jsonを以下のように書き換えます。

```diff
{
  "name": "learn-zig-to-be-a-beginner",
  "published": true,
- "publishedYear": 2023,
+ "publishedYear": 2023
  "chapters": [
    {
      "name": "introduction",
      "index": 0
    },
    {
      "name": "main",
      "index": 1
    },
    {
      "name": "conclusion",
      "index": 2
    }
  ]
}
```

実行してみると、`std.json.validate()` が `false` を返していることがわかります。

```shell
$ zig test src/main.zig
Test [1/1] test.test... FAIL (TestUnexpectedResult)
/home/drumato/.zig/lib/std/testing.zig:347:14: 0x213267 in expect (test)
    if (!ok) return error.TestUnexpectedResult;
             ^
src/main.zig:5:5: 0x2133ac in test.test (test)
    try std.testing.expect(std.json.validate(json_file));
    ^
0 passed; 0 skipped; 1 failed.
error: the following test command failed with exit code 1:
/home/drumato/tmp/zig-cache/o/304212365d2d3e29abdd99d3b321e5af/test
make: *** [Makefile:4: all] Error 1
```

## JSONのパース

次に、JSONパーサを使ってみます。
JSONパーサは、主に2つのインタフェースから利用することができます。

- `std.json.parse()` 
  - トークンストリームを作って、パーサに引き渡す方式
  - 実装: <https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/json.zig#L1712-L1721>
- `std.json.Parser.parse()`
  - パーサ構造体を定義して、JSON表現を直接引き渡す方式
  - 実装: <https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/json.zig#L1778>

今回は前者を利用してみます。

```zig
const std = @import("std");

const S = struct {
    name: []const u8,
    published: bool,
    publishedYear: isize,
    chapters: []Chapter,

    const Chapter = struct {
        name: []const u8,
        index: isize,
    };
};

test "test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const json_file = @embedFile("sample.json");
    var token_stream = std.json.TokenStream.init(json_file);

    const parse_opt = std.json.ParseOptions{
        .allocator = allocator,
    };
    const s = try std.json.parse(S, &token_stream, parse_opt);

    try std.testing.expect(std.mem.eql(u8, s.name, "learn-zig-to-be-a-beginner"));
    try std.testing.expect(s.published);
    try std.testing.expect(s.publishedYear == 2023);
    try std.testing.expect(s.chapters.len == 3);
}
```

構造体のメンバに対応する、JSONのフィールド値が格納されているのがわかります。

## 参考文献

- <https://ziglang.org/documentation/0.10.1/std/#root;json>

