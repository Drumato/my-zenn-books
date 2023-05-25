const std = @import("std");

const maximum_target_count: usize = 32;
const CommandLineOption = struct {
    targets: [maximum_target_count][]const u8 = undefined,
    target_count: usize = 0,
    all_files: bool = false,
};

pub fn main() !void {
    var args = std.process.ArgIterator.init();
    std.debug.assert(args.next() != null);

    const opt = try parseCmdArgs(&args);
    var stdout = std.io.getStdOut().writer();

    var index: usize = 0;
    while (index < opt.target_count) : (index += 1) {
        const target_path = opt.targets[index];

        const cwd = std.fs.cwd();

        const target_dir = if (std.fs.path.isAbsolute(target_path)) blk: {
            break :blk try std.fs.openIterableDirAbsolute(target_path, std.fs.Dir.OpenDirOptions{});
        } else else_blk: {
            break :else_blk try cwd.openIterableDir(target_path, std.fs.Dir.OpenDirOptions{});
        };

        var target_dir_entries = target_dir.iterate();
        while (try target_dir_entries.next()) |target_dir_entry| {
            const hide_file = !opt.all_files;
            if (hide_file and target_dir_entry.name[0] == '.') {
                continue;
            }

            try stdout.print("{s} ", .{target_dir_entry.name});
        }
    }
}

const CmdArgsParseError = error{
    MaximumTargetCountReached,
};

fn parseCmdArgs(
    args: *std.process.ArgIterator,
) CmdArgsParseError!CommandLineOption {
    var opt = CommandLineOption{};
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-a")) {
            opt.all_files = true;
            continue;
        }

        if (opt.target_count == 32) {
            return CmdArgsParseError.MaximumTargetCountReached;
        }

        opt.targets[opt.target_count] = arg;
        opt.target_count += 1;
    }

    return opt;
}
