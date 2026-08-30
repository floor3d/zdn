const std = @import("std");
const Io = std.Io;
const zdn = @import("zdn");
const util = @import("util.zig");
const zocket = @import("zocket.zig");
const config = @import("config.zig");
const logz = @import("logz.zig");

pub fn print_usage(io: Io) !void {
    var buf: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &buf);
    const stderr = &stderr_writer.interface;
    try stderr.print("USAGE: ./zdn [config_filepath]\n", .{});
    try stderr.flush();
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();
    var u = try util.Util._init(init);

    const args = try init.minimal.args.toSlice(arena);

    if (args.len < 2) {
        try print_usage(init.io);
        return;
    }

    const file_contents = try u.read_file(args[1], arena);
    defer arena.free(file_contents);
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

    var l = try logz.Logger._init(init, logfile_name);
    defer l.deinit();
    l.debug("Name: {s}, Type: {s}", .{ conf.name, conf.server_type });

    var nio_inner = zocket.C_NetIO{ .l = &l, .allocator = arena };
    const net_io = zocket.Generic_NetIO(zocket.C_NetIO){ .inner = &nio_inner };

    net_io.bind("0.0.0.0", 9798) catch {
        l.err("Failed to bind...", .{});
        return;
    };

    const sock = net_io.accept() catch {
        l.err("Failed to accept...", .{});
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
        l.debug("{s}", .{b});
    }

    net_io.close_bind();

    return;
}
