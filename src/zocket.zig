const std = @import("std");
const Io = std.Io;
const util = @import("util.zig");
const posix = std.posix;
const linux = std.os.linux;
const sockaddr = posix.sockaddr;
const sockaddr_storage = sockaddr.storage;
const sockaddr_in = sockaddr.in;
const sockaddr_in6 = sockaddr.in6;
const socklen_t = posix.socklen_t;

const errs = error{
    /// Couldn't bind on specified address and port.
    ErrBind,
    /// Call to `accept` failed for some reason, perhaps that there was nothing to accept
    ErrAccept,
};

/// Generic Socket Adapter
/// Standard interface for any kind of socket, ex. Zig or C sockets
/// Plug in any socket functionality by calling this method with your socket struct
/// and implementing the functions in the struct that this function returns
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

/// Generic Network IO Adapter
/// Standard interface for functions that set up network IO
/// Intuition: call `bind()` once, and each `accept()` call will give you
/// a generic socket to send and receive messages
/// Plug in any network IO by calling this method with your net IO struct
/// and implementing the functions in the struct that this function returns
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

/// A Plug-in struct to be used with Generic Net IO Adapter
/// Mirrors C network IO functions as found in `std.os.linux`:
/// `bind()`, `accept()`
/// Note that `bind()` covers both `bind()` and `listen()`
pub const C_NetIO = struct {
    u: util.Util,

    pub const socktype = C_Socket;
    var c_sock: usize = 0;

    pub fn get_socktype_str() []const u8 {
        return "C_Socket";
    }

    pub fn bind(self: C_NetIO, ip: []const u8, port: u16) errs!void {
        self.u.debug("Binding on {s}:{d}", .{ ip, port });

        // Plan: Just handle ipv4 for now because fuck the system!
        c_sock = linux.socket(std.c.AF.INET, std.c.SOCK.STREAM | std.c.SOCK.NONBLOCK, 0);
        if (c_sock > std.math.maxInt(usize) - 100) {
            self.u.err("Uh oh ... socket is {d}", .{c_sock});
            return errs.ErrBind;
        }

        self.u.debug("Socket: {d}", .{c_sock});

        const parsed_ip: Io.net.Ip4Address = Io.net.Ip4Address.parse(ip, port) catch {
            return errs.ErrBind;
        };

        // I do not really understand why `.little` is correct here and `.big` isn't
        const ip_addr: u32 = std.mem.readInt(u32, &parsed_ip.bytes, .little);

        const be_port = std.mem.nativeToBig(u16, parsed_ip.port);

        const s_in: sockaddr_in = .{ .family = posix.AF.INET, .port = be_port, .addr = ip_addr };

        const bind_result: usize = linux.bind(@as(i32, @intCast(c_sock)), @ptrCast(&s_in), @sizeOf(sockaddr_in));

        if (bind_result != 0) {
            self.u.err("Uh oh ... bind_result is {d}", .{std.math.maxInt(usize) - bind_result});
            return errs.ErrBind;
        }

        const listen_result: usize = linux.listen(@as(i32, @intCast(c_sock)), 10);

        if (listen_result != 0) {
            self.u.err("Uh oh ... listen_result is {d}", .{std.math.maxInt(usize) - listen_result});
            return errs.ErrBind;
        }

        self.u.info("Sleeping 10", .{});
        self.u.sleep(10);

        return;
    }

    // Self needs to be a pointer here so that when we return from the function,
    // the `C_Socket` stays valid and doesn't get wiped out with the function stack frame
    pub fn accept(self: *C_NetIO) errs!Generic_Socket(socktype) {
        // Placeholder
        var addr: sockaddr_in = std.mem.zeroes(sockaddr_in);
        var addr_len: socklen_t = 0;
        const sock: usize = linux.accept(@as(i32, @intCast(c_sock)), @ptrCast(&addr), &addr_len);
        if (sock > std.math.maxInt(usize) - 100) {
            self.u.err("Uh oh ... accept failed!", .{});
            return errs.ErrAccept;
        }
        var c_s = C_Socket._init(
            self,
            sock,
            addr,
        ) catch {
            return errs.ErrBind;
        };
        return Generic_Socket(C_Socket){ .inner = &c_s };
    }
};

/// A Plug-in struct to be used with Generic Socket Adapter
/// Made to mirror C socket functionality
pub const C_Socket = struct {
    parent: *C_NetIO,
    sock: usize,
    addr: sockaddr_in,

    pub fn _init(parent: *C_NetIO, sock: usize, addr: sockaddr_in) errs!C_Socket {
        return .{
            .parent = parent,
            .sock = sock,
            .addr = addr,
        };
    }

    pub fn write(self: C_Socket, msg: []const u8) errs!usize {
        self.parent.u.debug("Writing msg", .{});
        if (msg.len == 0) {
            return 0;
        }
        return 0;
    }

    pub fn recvmsg(self: C_Socket) errs![]const u8 {
        self.parent.u.debug("Receiving msg", .{});
        return "";
    }

    pub fn close(self: C_Socket) errs!void {
        self.parent.u.debug("Closing", .{});
        return;
    }
};
