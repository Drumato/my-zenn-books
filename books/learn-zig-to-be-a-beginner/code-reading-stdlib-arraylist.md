---
title: "std.ArrayListの実装を読む"
free: true
---

# std.ArrayListの実装を読む

ここからは少し趣向を変えて、Zigの標準ライブラリを読むことで実践的なZigプログラミングを学ぶことにします。
まずは、非常に汎用的なコレクション型の `std.ArrayList(T)` をご紹介します。
このコードリーディングによって、以下のような知見が得られることを期待します。

- 型を返す関数の使い方
- メモリアロケータ･インタフェースの使い方

本章全体を通して、以下の実装を引用しています。

<https://github.com/ziglang/zig/blob/0.10.1/lib/std/array_list.zig>

## 型定義部分

まずは、ユーザから最初に呼び出される、 `std.ArrayList(T)` という関数そのものを見てみましょう。

```zig
/// A contiguous, growable list of items in memory.
/// This is a wrapper around an array of T values. Initialize with `init`.
///
/// This struct internally stores a `std.mem.Allocator` for memory management.
/// To manually specify an allocator with each method call see `ArrayListUnmanaged`.
pub fn ArrayList(comptime T: type) type {
    return ArrayListAligned(T, null);
}
```

返り値の型が `type` になっている点に注目です。
どうやら内部的には `ArrayListAligned()` を利用しているのと同じようですね。
`ArrayListAligned()` の定義は非常に長いので、少しずつ切り出して紹介します。

実際に、 `ArrayListAligned()` の中から、
`return struct` する部分までと、メンバ定義および `init()/deinit()` が含まれた部分までを以下に示します。

```zig
/// A contiguous, growable list of arbitrarily aligned items in memory.
/// This is a wrapper around an array of T values aligned to `alignment`-byte
/// addresses. If the specified alignment is `null`, then `@alignOf(T)` is used.
/// Initialize with `init`.
///
/// This struct internally stores a `std.mem.Allocator` for memory management.
/// To manually specify an allocator with each method call see `ArrayListAlignedUnmanaged`.
pub fn ArrayListAligned(comptime T: type, comptime alignment: ?u29) type {
    if (alignment) |a| {
        if (a == @alignOf(T)) {
            return ArrayListAligned(T, null);
        }
    }
    return struct {
        const Self = @This();
        /// Contents of the list. Pointers to elements in this slice are
        /// **invalid after resizing operations** on the ArrayList, unless the
        /// operation explicitly either: (1) states otherwise or (2) lists the
        /// invalidated pointers.
        ///
        /// The allocator used determines how element pointers are
        /// invalidated, so the behavior may vary between lists. To avoid
        /// illegal behavior, take into account the above paragraph plus the
        /// explicit statements given in each method.
        items: Slice,
        /// How many T values this list can hold without allocating
        /// additional memory.
        capacity: usize,
        allocator: Allocator,

        pub const Slice = if (alignment) |a| ([]align(a) T) else []T;

        /// Deinitialize with `deinit` or use `toOwnedSlice`.
        pub fn init(allocator: Allocator) Self {
            return Self{
                .items = &[_]T{},
                .capacity = 0,
                .allocator = allocator,
            };
        }

        // 省略

        /// Release all allocated memory.
        pub fn deinit(self: Self) void {
            if (@sizeOf(T) > 0) {
                self.allocator.free(self.allocatedSlice());
            }
        }

        // 省略
    };
}
```

2つ目の引数で渡されたアラインメントは `comptime` がつけられており、
`items` メンバの型に `[]align(n) T` を修飾することができます。
内部では、 `std.mem.Allocator` を保持しており、これを利用して動的にメモリ管理を行います。
また、`deinit()` では、単に `std.mem.Allocator.free()` を呼び出して、メモリを開放します。

## 要素追加

次に、ある要素を末尾に追加する、 `append()` 関連の実装を見てみます。

```zig
pub fn ArrayListAligned(comptime T: type, comptime alignment: ?u29) type {
    // 省略
    return struct {
        // 省略

        /// Extend the list by 1 element. Allocates more memory as necessary.
        /// Invalidates pointers if additional memory is needed.
        pub fn append(self: *Self, item: T) Allocator.Error!void {
            const new_item_ptr = try self.addOne();
            new_item_ptr.* = item;
        }

        /// Increase length by 1, returning pointer to the new item.
        /// The returned pointer becomes invalid when the list resized.
        pub fn addOne(self: *Self) Allocator.Error!*T {
            const newlen = self.items.len + 1;
            try self.ensureTotalCapacity(newlen);
            return self.addOneAssumeCapacity();
        }

        /// Increase length by 1, returning pointer to the new item.
        /// Asserts that there is already space for the new item without allocating more.
        /// The returned pointer becomes invalid when the list is resized.
        /// **Does not** invalidate element pointers.
        pub fn addOneAssumeCapacity(self: *Self) *T {
            assert(self.items.len < self.capacity);

            self.items.len += 1;
            return &self.items[self.items.len - 1];
        }

        // 省略
```

`append()` は、追加する要素を配置するメモリ領域のアドレスに書き込むという、シンプルなものです。
メンバの `items` のアドレスを取得する部分は、 `addOneAssumeCapacity()` で行っています。
ここで、動的にメモリサイズを伸長するバッファを扱うデータ構造を実装した人はピンと来ると思いますが、
`ensureTotalCapacity()` で、今後の要素追加時に毎回アロケーションを行わないように、
多めにバッファを確保します。

ということで、その実装を見ていきましょう。

```zig
pub fn ArrayListAligned(comptime T: type, comptime alignment: ?u29) type {
    // 省略
    return struct {
        // 省略

        /// Modify the array so that it can hold at least `new_capacity` items.
        /// Invalidates pointers if additional memory is needed.
        pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) Allocator.Error!void {
            if (@sizeOf(T) > 0) {
                if (self.capacity >= new_capacity) return;

                var better_capacity = self.capacity;
                while (true) {
                    better_capacity +|= better_capacity / 2 + 8;
                    if (better_capacity >= new_capacity) break;
                }

                return self.ensureTotalCapacityPrecise(better_capacity);
            } else {
                self.capacity = math.maxInt(usize);
            }
        }

        /// Modify the array so that it can hold at least `new_capacity` items.
        /// Like `ensureTotalCapacity`, but the resulting capacity is much more likely
        /// (but not guaranteed) to be equal to `new_capacity`.
        /// Invalidates pointers if additional memory is needed.
        pub fn ensureTotalCapacityPrecise(self: *Self, new_capacity: usize) Allocator.Error!void {
            if (@sizeOf(T) > 0) {
                if (self.capacity >= new_capacity) return;

                // TODO This can be optimized to avoid needlessly copying undefined memory.
                const new_memory = try self.allocator.reallocAtLeast(self.allocatedSlice(), new_capacity);
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            } else {
                self.capacity = math.maxInt(usize);
            }
        }

        // 省略
```

今回はデータ構造の実装法を理解したいわけではないので、
`better_capacity` の計算法については解説しません。
`ensureTotalCapacityPrecise()` で、 `reallocAtLeast()` を呼び出して、新しいキャパシティでメモリを確保しつつ、それをメンバに格納します。

重要なのは、 実装全体を通して `Allocator.Error` を返しているところです。
もちろん `anyerror` を返すことも可能ですが、
個人的には、エラーの種類が明示されていたほうが、フレンドリーなコードだと思っているので、このプラクティスはとても参考になります。
