const std = @import("std");
const Io = std.Io;

const zdn = @import("zdn");
const util = @import("util.zig");

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;
    var buffer: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &buffer);
    const stderr = &stderr_writer.interface;
    var u = util.Util._init(init, stderr);

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        u.info("arg: {s}", .{arg});
    }

    u.info("Yo", .{});
    u.debug("Yo", .{});
    u.warn("Yo", .{});
    u.err("Yo", .{});
    return;
}
