const std = @import("std");
const Io = std.Io;
const zdn = @import("zdn");
const util = @import("util.zig");
const zocket = @import("zocket.zig");
const config = @import("config.zig");

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();
    var u = util.Util._init(init);
    defer u.deinit(arena);

    const args = try init.minimal.args.toSlice(arena);

    if (args.len < 2) {
        u.err("No filepath given.", .{});
        u.print_usage();
        return;
    }

    u.info("Using configuration file: {s}", .{args[1]});

    const file_contents = try u.read_file(args[1], arena);
    defer arena.free(file_contents);
    u.debug("{s}", .{file_contents});
    const parsed = try std.json.parseFromSlice(
        config.Config,
        arena,
        file_contents,
        .{},
    );
    defer parsed.deinit();
    const conf = parsed.value;
    var logfile_name_buf: [128]u8 = undefined;
    const logfile_name = std.fmt.bufPrint(&logfile_name_buf, "logs/{s}_{s}.log", .{ conf.name, conf.server_type }) catch unreachable;
    u.set_logger(logfile_name, arena);
    u.debug("EXPECT STUFF HERE", .{});
    u.debug("Name: {s}, Type: {s}", .{ conf.name, conf.server_type });

    var nio_inner = zocket.C_NetIO{ .u = u, .allocator = arena };
    const net_io = zocket.Generic_NetIO(zocket.C_NetIO){ .inner = &nio_inner };

    net_io.bind("0.0.0.0", 9798) catch {
        u.err("Failed to bind...", .{});
        return;
    };

    const sock = net_io.accept() catch {
        u.err("Failed to accept...", .{});
        return;
    };

    _ = sock.write("Yo\n") catch {};
    while (true) {
        const socks = [1]@TypeOf(sock){sock};
        var results: [3]@TypeOf(sock) = undefined;
        try net_io.pollfds(&socks, &results, 5);
        var buf = std.mem.zeroes([4096:0]u8);
        const n = sock.recv(&buf, buf.len) catch 0;
        const b = buf[0..n];
        u.debug("{s}", .{b});
    }

    net_io.close_bind();

    return;
}
