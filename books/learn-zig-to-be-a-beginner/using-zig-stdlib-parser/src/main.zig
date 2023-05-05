const std = @import("std");
const debug = std.debug;
const process = std.process;
const fs = std.fs;
const zig = std.zig;

pub fn main() !void {
    var args = process.ArgIteratorPosix.init();

    if (args.count < 2) {
        debug.print("usage: using-zig-stdlib-parser <zig-file>", .{});
        process.exit(1);
    }

    debug.assert(args.next() != null);
    const relative_filepath = args.next().?;
    const file = try fs.cwd().openFile(relative_filepath, fs.File.OpenFlags{});

    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 0 }){};
    const allocator = gpa.allocator();

    const zig_source = try file.readToEndAllocOptions(allocator, 4096, 4096, @alignOf(u8), 0);
    defer allocator.free(zig_source);

    var tree = try zig.parse(allocator, zig_source);
    defer tree.deinit(allocator);

    const stdout = std.io.getStdOut().writer();
    for (tree.rootDecls()) |root_decl_index, i| {
        try stdout.print("root decls[{}]: {s}\n", .{ i, tree.getNodeSource(root_decl_index) });
    }
}
