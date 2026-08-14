const std = @import("std");
const Io = std.Io;
const zdn = @import("zdn");
const util = @import("util.zig");
const zocket = @import("zocket.zig");

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();
    var u = util.Util._init(init);

    const args = try init.minimal.args.toSlice(arena);

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

    var nio_inner = zocket.C_NetIO{ .u = u, .allocator = arena };
    const net_io = zocket.Generic_NetIO(zocket.C_NetIO){ .inner = &nio_inner };

    // net_io.bind("127.0.0.1", 9797) catch {};

    // const sock = net_io.accept() catch {
    //     u.err("Quitting early!", .{});
    //     return;
    // };

    // sock.close();

    // TODO: This kind of sucks. I should just make it one surface struct and just deal with several generic NetIO's
    // instead of getting sockets from the generic NetIOs (?)
    const sock = try net_io.connect("127.0.0.1", 9797, 3);

    u.sleep(2);

    sock.close();

    return;
}
