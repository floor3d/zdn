const std = @import("std");
const Io = std.Io;
const util = @import("util.zig");
const logz = @import("logz.zig");
const zocket = @import("zocket.zig");
const C_NetIO = zocket.C_NetIO;
const Generic_NetIO = zocket.Generic_NetIO;
/// Simulates a client that is requesting for information from a CDN
pub const Client = struct {
    init: std.process.Init,
    allocator: std.mem.Allocator,
    l: *logz.Logger,
    server_address: []u8,
    server_port: u16,
    server_socket: Generic_NetIO(C_NetIO),

    pub fn _init(init: std.process.Init, allocator: std.mem.Allocator, l: *logz.Logger) !Client {
        var self: Client = .{
            .init = init,
            .allocator = allocator,
            .l = l,
            .server_address = undefined,
            .server_port = undefined,
            .server_socket = undefined,
        };
        _ = try std.Thread.spawn(.{}, discover, .{&self});
        return self;
    }

    fn discover(self: *Client) void {
        self.server_address = "0.0.0.0";
    }
};

// Plan
// 1. Create hyper simple http library
// 2. Keep connection alive, but if connection drops, use "dns" to resolve and re-create connection (create fake dns service)
// 3. http advertises: session(), get(), post(); all use timeout logic under the hood
