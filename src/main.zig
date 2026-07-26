const std = @import("std");
const Io = std.Io;
const zdn = @import("zdn");
const util = @import("util.zig");

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
    }

    u.info("Using configuration file: {s}", .{args[1]});

    var file_contents: [4096]u8 = undefined;
    const config_file_size: usize = try u.read_file("/home/evand/Programming/zdn/README.md", &file_contents);
    u.info("{d}: {s}", .{ config_file_size, file_contents });

    return;
}
