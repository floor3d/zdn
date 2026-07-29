const std = @import("std");
const Io = std.Io;
const zdn = @import("zdn");
const util = @import("util.zig");
const zocket = @import("zocket.zig");

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();
    var u = util.Util._init(init);

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |_| {
        // u.info("arg: {s}", .{arg});
    }

    if (args.len < 2) {
        u.err("No filepath given.", .{});
        u.print_usage();
        return;
    }

    u.info("Using configuration file: {s}", .{args[1]});

    var file_contents: [4096]u8 = undefined;
    const config_file_size = u.read_file(args[1], &file_contents) catch 0;
    if (config_file_size == 0) {
        u.err("Failed to read file!", .{});
        return;
    }

    const z = zocket.Zocket._init(init);
    u.info("{any}", .{z});

    return;
}
