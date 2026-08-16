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
const success = linux.E.SUCCESS;

const errs = error{
    /// Couldn't bind on specified address and port.
    ErrBind,
    /// Call to `accept` failed for some reason, perhaps that there was nothing to accept
    ErrAccept,
    /// Call to linux `socket` failed
    ErrSocket,
    /// Call to linux `connect` failed
    ErrConnect,
    /// Call to linux `listen` failed
    ErrListen,
    /// Failed to parse IP Address
    ErrParseIP,
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

        pub fn _close(self: Self) void {
            self.inner._close();
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

        pub fn connect(self: Self, ip: []const u8, port: u16, timeout: u16) errs!Generic_Socket(T.socktype) {
            return self.inner.connect(ip, port, timeout);
        }

        pub fn close(self: Self, generic_sock: Generic_Socket(T.socktype)) void {
            return self.inner.close(generic_sock);
        }

        pub fn close_bind(self: Self) void {
            return self.inner.close_bind();
        }
    };
}

/// A Plug-in struct to be used with Generic Net IO Adapter
/// Mirrors C network IO functions as found in `std.os.linux`:
/// `bind()`, `accept()`
/// Note that `bind()` covers both `bind()` and `listen()`
pub const C_NetIO = struct {
    u: util.Util,
    c_sock: usize = 0,
    allocator: std.mem.Allocator,

    pub const socktype = C_Socket;

    pub fn get_socktype_str() []const u8 {
        return "C_Socket";
    }

    pub fn ip_port_to_sockaddr(ip: []const u8, port: u16) errs!sockaddr_in {
        const parsed_ip: Io.net.Ip4Address = Io.net.Ip4Address.parse(ip, port) catch {
            return errs.ErrParseIP;
        };

        // I do not really understand why `.little` is correct here and `.big` isn't
        const ip_addr: u32 = std.mem.readInt(u32, &parsed_ip.bytes, .little);

        const be_port = std.mem.nativeToBig(u16, parsed_ip.port);

        const s_in: sockaddr_in = .{ .family = posix.AF.INET, .port = be_port, .addr = ip_addr };

        return s_in;
    }

    pub fn bind(self: *C_NetIO, ip: []const u8, port: u16) errs!void {
        self.u.debug("Binding on {s}:{d}", .{ ip, port });

        // Plan: Just handle ipv4 for now because fuck the system!
        self.c_sock = linux.socket(std.c.AF.INET, std.c.SOCK.STREAM | std.c.SOCK.NONBLOCK, 0);
        if (linux.errno(self.c_sock) != success) {
            self.u.err("Uh oh ... socket is {d}", .{self.c_sock});
            return errs.ErrSocket;
        }

        self.u.debug("Socket: {d}", .{self.c_sock});

        const s_in = try ip_port_to_sockaddr(ip, port);

        const bind_result: usize = linux.bind(@as(i32, @intCast(self.c_sock)), @ptrCast(&s_in), @sizeOf(sockaddr_in));

        if (linux.errno(bind_result) != success) {
            self.u.err("Uh oh ... bind_result is {d}", .{std.math.maxInt(usize) - bind_result});
            return errs.ErrBind;
        }

        const listen_result: usize = linux.listen(@as(i32, @intCast(self.c_sock)), 10);

        if (linux.errno(listen_result) != success) {
            self.u.err("Uh oh ... listen_result is {d}", .{std.math.maxInt(usize) - listen_result});
            return errs.ErrListen;
        }

        return;
    }

    // Self needs to be a pointer here so that when we return from the function,
    // the `C_Socket` stays valid and doesn't get wiped out with the function stack frame
    pub fn accept(self: *C_NetIO) errs!Generic_Socket(socktype) {
        var addr: sockaddr_in = std.mem.zeroes(sockaddr_in);
        var addr_len: socklen_t = @sizeOf(sockaddr_in);
        const sock: usize = linux.accept(@as(i32, @intCast(self.c_sock)), @ptrCast(&addr), &addr_len);
        try self.poll_on_sock_accept(sock, 10);
        if (linux.errno(sock) != success) {
            self.u.err("Uh oh ... accept failed!", .{});
            return errs.ErrSocket;
        }
        var c_s: *C_Socket = self.allocator.create(C_Socket) catch {
            return errs.ErrConnect;
        };
        c_s._init(self, sock, addr);
        return Generic_Socket(C_Socket){ .inner = c_s };
    }

    pub fn poll_on_sock_connect(self: C_NetIO, sock_fd: usize, connect_res: usize, timeout: u16) errs!void {
        const en = linux.errno(connect_res);
        if (en != success and en != linux.E.INPROGRESS) {
            self.u.err("Call to connect failed with errno {any}!", .{en});
            return errs.ErrConnect;
        }

        try self.poll_on_sock(sock_fd, timeout);
    }

    pub fn poll_on_sock_accept(self: C_NetIO, accept_res: usize, timeout: u16) errs!void {
        const en = linux.errno(accept_res);
        // No WOULDBLOCK exists in linux.E; it's synonymous with .AGAIN according to the source
        if (en != success and en != linux.E.AGAIN) {
            self.u.err("Call to accept failed with errno {any}!", .{en});
            return errs.ErrConnect;
        }

        try self.poll_on_sock(accept_res, timeout);
    }

    pub fn poll_on_sock(self: C_NetIO, sock_fd: usize, timeout: u16) errs!void {
        self.u.debug("Sock fd is {any}", .{sock_fd});
        var en = linux.errno(sock_fd);
        std.debug.assert(en == success);
        var pfd: linux.pollfd = std.mem.zeroes(linux.pollfd);
        pfd.fd = sock_fd; //@as(i32, @intCast(sock_fd));
        pfd.events = linux.POLL.OUT;

        const poll_result: usize = linux.poll((&pfd)[0..1], 1, @as(i32, @intCast(timeout)));
        en = linux.errno(poll_result);

        if (en != success) {
            self.u.err("POLL failed with errno {any}!", .{en});
            return errs.ErrConnect;
        }

        if (poll_result == 0) {
            self.u.err("POLL timed out!", .{});
            return errs.ErrConnect;
        }

        if (pfd.revents & (linux.POLL.OUT | linux.POLL.ERR | linux.POLL.HUP) == 0) {
            self.u.err("No PFD revents!", .{});
            return errs.ErrConnect;
        }

        var so_error: i32 = 0;
        var socklen: socklen_t = 0;

        const gso_result: usize = linux.getsockopt(@as(i32, @intCast(sock_fd)), linux.SOL.SOCKET, linux.SO.ERROR, @ptrCast(&so_error), &socklen);
        en = linux.errno(gso_result);
        if (en != success) {
            self.u.err("getsockopt() failed with errno {any}!", .{en});
            return errs.ErrConnect;
        }

        if (so_error != 0) {
            self.u.err("Socket failed to connect with errno {any}!", .{so_error});
            return errs.ErrConnect;
        }
    }

    // Self needs to be a pointer here so that when we return from the function,
    // the `C_Socket` stays valid and doesn't get wiped out with the function stack frame
    pub fn connect(self: *C_NetIO, ip: []const u8, port: u16, timeout: u16) errs!Generic_Socket(socktype) {
        self.u.debug("Connecting to {s}:{d}", .{ ip, port });

        // Plan: Just handle ipv4 for now because fuck the system!
        self.c_sock = linux.socket(std.c.AF.INET, std.c.SOCK.STREAM | std.c.SOCK.NONBLOCK, 0);
        if (linux.errno(self.c_sock) != success) {
            self.u.err("Failed to create socket!", .{});
            return errs.ErrSocket;
        }

        const s_in: sockaddr_in = try ip_port_to_sockaddr(ip, port);
        const connect_result: usize = linux.connect(@as(i32, @intCast(self.c_sock)), &s_in, @sizeOf(sockaddr_in));
        try self.poll_on_sock_connect(self.c_sock, connect_result, timeout);
        var c_s: *C_Socket = self.allocator.create(C_Socket) catch {
            return errs.ErrConnect;
        };
        errdefer self.allocator.destroy(c_s);
        c_s._init(self, self.c_sock, s_in);

        return Generic_Socket(C_Socket){ .inner = c_s };
    }

    pub fn close(self: C_NetIO, generic_sock: Generic_Socket(C_Socket)) void {
        generic_sock._close();
        self.allocator.destroy(&generic_sock);
        return;
    }

    pub fn close_bind(self: C_NetIO) void {
        const close_result: usize = linux.close(@as(i32, @intCast(self.c_sock)));
        if (linux.errno(close_result) != success) {
            self.u.err("Failed to close bind socket!", .{});
        }
    }
};

/// A Plug-in struct to be used with Generic Socket Adapter
/// Made to mirror C socket functionality
pub const C_Socket = struct {
    parent: *C_NetIO,
    sock: usize,
    addr: sockaddr_in,

    pub fn _init(self: *C_Socket, parent: *C_NetIO, sock: usize, addr: sockaddr_in) void {
        self.parent = parent;
        self.sock = sock;
        self.addr = addr;
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

    pub fn _close(self: C_Socket) void {
        const close_result: usize = linux.close(@as(i32, @intCast(self.sock)));
        if (linux.errno(close_result) != success) {
            self.parent.u.err("Failed to close socket!", .{});
        }
    }
};
