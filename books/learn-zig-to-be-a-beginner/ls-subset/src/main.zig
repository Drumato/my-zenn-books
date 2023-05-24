const std = @import("std");

pub fn main() !void {
    var args = std.process.ArgIterator.init();
    std.debug.assert(args.next() != null);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    _ = std.io.getStdOut().writer();

    while (args.next()) |arg| {
        const cwd = std.fs.cwd();

        const target_dir = if (std.fs.path.isAbsolute(arg)) blk: {
            break :blk try std.fs.openIterableDirAbsolute(arg, std.fs.Dir.OpenDirOptions{});
        } else blk: {
            break :blk try cwd.openIterableDir(arg, std.fs.Dir.OpenDirOptions{});
        };
        const entries = try listEntriesInDir(allocator, &target_dir);
        defer entries.deinit();
    }
}

fn listEntriesInDir(
    allocator: std.mem.Allocator,
    target_dir: *const std.fs.IterableDir,
) !std.ArrayList([]const u8) {
    var entry_names = std.ArrayList([]const u8).init(allocator);

    var target_dir_entries = target_dir.iterate();
    while (try target_dir_entries.next()) |target_dir_entry| {
        try entry_names.append(target_dir_entry.name);
    }

    return entry_names;
}
