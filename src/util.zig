const std = @import("std");
pub const level = std.log.Level;
const Io = std.Io;

const red = "\x1b[31m";
const yellow = "\x1b[33m";
const cyan = "\x1b[34m";
const reset = "\x1b[0m";

pub const Util = struct {
    init: std.process.Init,
    buffer: [1024]u8,

    pub fn _init(init: std.process.Init) Util {
        return .{
            .init = init,
            .buffer = undefined,
        };
    }

    fn printf(self: Util, comptime format: []const u8, args: anytype) void {
        const new_format = format ++ "\n";
        self.printf_no_n(new_format, args);
    }

    fn printf_no_n(self: Util, comptime format: []const u8, args: anytype) void {
        // This dumb shit is required to get a mutable `self`
        var s = self;
        var stderr = std.Io.File.stderr().writer(s.init.io, &s.buffer);
        var writer = &stderr.interface;
        writer.print(format, args) catch {};
        writer.print("{s}", .{reset}) catch {};
        writer.flush() catch {};
    }

    pub fn print_prefix(self: Util, lev: level) !void {
        var datetime_buf: [32]u8 = undefined;
        const pre = self.now(&datetime_buf);
        self.printf_no_n("[{s}] ", .{pre});
        switch (lev) {
            .info => self.printf_no_n("INFO:  ", .{}),
            .debug => self.printf_no_n("{s}DEBUG: ", .{cyan}),
            .warn => self.printf_no_n("{s}WARN:  ", .{yellow}),
            .err => self.printf_no_n("{s}ERROR: ", .{red}),
        }
    }

    pub fn info(
        self: Util,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.info) catch {};
        self.printf(format, args);
    }

    pub fn debug(
        self: Util,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.debug) catch {};
        self.printf(format, args);
    }

    pub fn warn(
        self: Util,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.warn) catch {};
        self.printf(format, args);
    }

    pub fn err(
        self: Util,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.err) catch {};
        self.printf(format, args);
    }

    pub fn now(self: Util, date_time_str: *[32]u8) []const u8 {
        const t = Io.Clock.real.now(self.init.io);
        const n: u64 = @as(u64, @intCast(t.toSeconds()));
        const epoch_sec_struct = std.time.epoch.EpochSeconds{ .secs = n };
        const epoch_day = epoch_sec_struct.getEpochDay();
        const year_and_day = epoch_day.calculateYearDay();
        const year = year_and_day.year;
        const month_day = year_and_day.calculateMonthDay();
        const month = month_day.month;
        const day = month_day.day_index + 1;
        const day_seconds = epoch_sec_struct.getDaySeconds();
        const hour = day_seconds.getHoursIntoDay();
        const minute = day_seconds.getMinutesIntoHour();
        const second = day_seconds.getSecondsIntoMinute();

        const ret = std.fmt.bufPrint(date_time_str, "{d}-{d:02}-{d:02} {d:02}:{d:02}:{d:02}", .{ year, month, day, hour, minute, second }) catch unreachable;
        return ret;
    }

    pub fn print_usage(self: Util) void {
        self.info("USAGE: ./zdn [config_filepath]", .{});
    }

    pub fn read_file(self: Util, filepath: []const u8, file_contents: *[4096]u8) !usize {
        var alloc: std.heap.DebugAllocator(.{}) = .init;
        defer _ = alloc.deinit();
        const allocator = alloc.allocator();

        var threaded: std.Io.Threaded = .init(allocator, .{
            .argv0 = .init(self.init.minimal.args),
            .environ = self.init.minimal.environ,
        });
        defer threaded.deinit();
        const tio = threaded.io();

        var file = try std.Io.Dir.cwd().openFile(tio, filepath, .{ .mode = .read_only });
        defer file.close(tio);

        var read_buf: [4096]u8 = undefined;
        var file_reader = file.reader(tio, &read_buf);
        const reader = &file_reader.interface;
        var contents: [4096]u8 = undefined;
        const n: usize = try reader.readSliceShort(&contents);
        @memcpy(file_contents, contents[0..]);
        return n;
    }
};
