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
// 1. Make it so that the socket library works with UDP
// 2. Start thread that sends a beacon with a nonce every .8-1.2 seconds to 255.255.255.255
// 3. Poll on that UDP socket and see if we get anything back; if not, send another broadcast
// 4. Once we get a response back, check that the nonce matches, and if so, Yay! We found our server!
// 5. max tries = 100 or something
