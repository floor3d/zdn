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

    // const sock = try net_io.connect("127.0.0.1", 9797, 3);

    // net_io.close(sock);

    net_io.bind("0.0.0.0", 9798) catch {
        u.err("Failed to bind...", .{});
        return;
    };

    const sock = net_io.accept() catch {
        u.err("Failed to accept...", .{});
        return;
    };

    _ = sock.write("Yo\n") catch {};

    net_io.close_bind();

    return;
}
