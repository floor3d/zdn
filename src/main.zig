const std = @import("std");
const Io = std.Io;

const zdn = @import("zdn");
const util = @import("util.zig");

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    // util.print("All your {s} are belong to us.\n", .{"codebase"});

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    return run();
}

pub fn run() !void {
    util.info("Yo", .{});
    // util.print("Yo", .{});
    // util.warn("Yo", .{});
    // util.err("Yo", .{});
}
