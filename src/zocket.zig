const std = @import("std");
const Io = std.Io;
const sockaddr_storage = std.os.linux.sockaddr.storage;
const sockaddr_in = std.os.linux.sockaddr.in;
const sockaddr_in6 = std.os.linux.sockaddr.in6;
const util = @import("util.zig");

const errs = error{
    /// Couldn't bind on specified address and port.
    ErrBind,
};

pub fn Generic_Socket(comptime T: type) type {
    return struct {
        inner: *T,

        const Self = @This();

        pub fn write(self: Self, msg: []const u8) errs!usize {
            return self.inner.write(msg);
        }

        pub fn recvmsg(self: Self) errs![]const u8 {
            return self.inner.recvmsg();
        }

        pub fn close(self: Self) errs!void {
            return self.inner.close();
        }
    };
}

pub fn Generic_NetIO(comptime T: type) type {
    return struct {
        inner: *T,

        const Self = @This();

        pub fn bind(self: Self, ip: []const u8, port: u16) errs!void {
            return self.inner.bind(ip, port);
        }

        pub fn accept(self: Self) errs!Generic_Socket(T.socktype) {
            return self.inner.accept();
        }
    };
}

pub const C_NetIO = struct {
    u: util.Util,

    pub const socktype = C_Socket;

    pub fn get_socktype_str() []const u8 {
        return "C_Socket";
    }

    pub fn bind(self: C_NetIO, ip: []const u8, port: u16) errs!void {
        self.u.info("{s} {s}:{d}", .{ get_socktype_str(), ip, port });
        return;
    }

    // Self needs to be a pointer here so that when we return from the function,
    // the `C_Socket` stays valid and doesn't get wiped out with the function stack frame
    pub fn accept(self: *C_NetIO) errs!Generic_Socket(socktype) {
        // Placeholder
        var c_s = C_Socket._init(self) catch {
            return errs.ErrBind;
        };
        return Generic_Socket(C_Socket){ .inner = &c_s };
    }
};

pub const C_Socket = struct {
    parent: *C_NetIO,

    // Plan: Just handle ipv4 for now because fuck the system!
    pub fn _init(parent: *C_NetIO) errs!C_Socket {
        return .{
            .parent = parent,
        };
    }

    pub fn write(self: C_Socket, msg: []const u8) errs!usize {
        self.parent.u.info("Writing msg", .{});
        if (msg.len == 0) {
            return 0;
        }
        return 0;
    }

    pub fn recvmsg(self: C_Socket) errs![]const u8 {
        self.parent.u.info("Receiving msg", .{});
        return "";
    }

    pub fn close(self: C_Socket) errs!void {
        self.parent.u.info("Closing", .{});
        return;
    }
};
