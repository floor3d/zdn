const std = @import("std");
const Io = std.Io;
const util = @import("util.zig");
const logz = @import("logz.zig");
const zocket = @import("zocket.zig");
const C_NetIO = zocket.C_NetIO;
const Generic_NetIO = zocket.Generic_NetIO;
/// Single-session HTTP Client w/ automatic KeepAlive
pub const HttpClient = struct {
    init: std.process.Init,
    allocator: std.mem.Allocator,
    l: *logz.Logger,
    server_url: []u8,
    server_socket: Generic_NetIO(C_NetIO),

    pub fn _init(init: std.process.Init, allocator: std.mem.Allocator, l: *logz.Logger, server_url: []u8) !HttpClient {
        var self: HttpClient = .{
            .init = init,
            .allocator = allocator,
            .l = l,
            .server_url = [server_url.len]u8,
            .server_socket = undefined,
        };
        @memcpy(self.server_url, server_url);
        try self.session();
        return self;
    }

    fn session(self: *HttpClient) !void {
        self.server_socket = Generic_NetIO(C_NetIO);
    }
};

// Plan
// 1. Create hyper simple http library, for both client and server (rip)
// 2. Keep connection alive, but if connection drops, use "dns" to resolve and re-create connection (create fake dns service)
// 3. http advertises: session(), get(), post(); all use timeout logic under the hood

pub const HttpServer = struct {
    init: std.process.Init,
    allocator: std.mem.Allocator,
    l: *logz.Logger,
    server_url: []u8,
    server_socket: Generic_NetIO(C_NetIO),

    pub fn _init(init: std.process.Init, allocator: std.mem.Allocator, l: *logz.Logger, server_url: []u8) !HttpServer {
        var self: HttpServer = .{
            .init = init,
            .allocator = allocator,
            .l = l,
            .server_url = [server_url.len]u8,
            .server_socket = undefined,
        };
        @memcpy(self.server_url, server_url);
        try self.session();
        return self;
    }

    fn session(self: *HttpServer) !void {
        self.server_socket = Generic_NetIO(C_NetIO);
    }
};
