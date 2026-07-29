const std = @import("std");
const Io = std.Io;
const sockaddr_storage = std.os.linux.sockaddr.storage;
const sockaddr_in = std.os.linux.sockaddr.in;
const sockaddr_in6 = std.os.linux.sockaddr.in6;

const errs = error{
    /// Couldn't bind on specified address and port.
    ErrBind,
};

///TODO: MAKE THIS ABSTRACTED TO SOCKET TYPE ... dependency injection or something
pub const Zocket = struct {
    init: std.process.Init,
    // Plan: Just handle ipv4 for now because fuck the system!
    ip: []const u8,
    port: i16,

    pub fn _init(init: std.process.Init) errs!Zocket {
        var self = Zocket{
            .init = init,
            .ip = "",
            .port = 0,
        };
        try self.bind();
        return self;
    }

    pub fn bind(self: Zocket) errs!void {
        if (self.ip.len == 0) {
            // Empty IP.
            return errs.ErrBind;
        }
        return;
    }
};
