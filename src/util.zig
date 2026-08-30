const std = @import("std");
pub const level = std.log.Level;
const Io = std.Io;

const red = "\x1b[31m";
const yellow = "\x1b[33m";
const cyan = "\x1b[34m";
const reset = "\x1b[0m";

pub const Util = struct {
    init: std.process.Init,
    buffer: [4096]u8,
    log_buffer: [4096]u8,
    filepath: ?[]u8,

    pub fn _init(init: std.process.Init) Util {
        return .{
            .init = init,
            .buffer = undefined,
            .log_buffer = undefined,
            .filepath = null,
        };
    }

    pub fn deinit(self: Util, allocator: std.mem.Allocator) void {
        const fp = self.filepath orelse return;
        allocator.free(fp);
    }

    fn printf(self: Util, comptime format: []const u8, args: anytype) void {
        const new_format = format ++ "\n";
        self.printf_no_n(new_format, args);
        self.log(new_format, args);
    }

    fn printf_no_n(self: Util, comptime format: []const u8, args: anytype) void {
        // This dumb shit is required to get a mutable `self`
        var s = self;
        var stderr = Io.File.stderr().writer(s.init.io, &s.buffer);
        var writer = &stderr.interface;
        writer.print(format, args) catch {};
        writer.print("{s}", .{reset}) catch {};
        writer.flush() catch {};
    }

    pub fn print_prefix(self: Util, lev: level) !void {
        var datetime_buf: [32]u8 = undefined;
        const pre = self.now(&datetime_buf);
        self.printf_no_n("[{s}] ", .{pre});
        self.log("[{s}] ", .{pre});
        switch (lev) {
            .info => {
                self.printf_no_n("INFO:  ", .{});
                self.log("INFO:  ", .{});
            },
            .debug => {
                self.printf_no_n("{s}DEBUG: ", .{cyan});
                self.log("{s}DEBUG: ", .{cyan});
            },
            .warn => {
                self.printf_no_n("{s}WARN:  ", .{yellow});
                self.log("{s}WARN:  ", .{yellow});
            },
            .err => {
                self.printf_no_n("{s}ERROR: ", .{red});
                self.log("{s}ERROR: ", .{red});
            },
        }
    }

    pub fn set_logger(self: *Util, filepath: []u8, allocator: std.mem.Allocator) void {
        self.filepath = allocator.alloc(u8, filepath.len) catch |er| {
            self.err("Failed to allocate: {any}", .{er});
            return;
        };
        const fp = self.filepath orelse {
            return;
        };
        @memcpy(fp, filepath);

        const file = Io.Dir.cwd().createFile(self.init.io, fp, .{}) catch {
            return;
        };
        file.close(self.init.io);
    }

    pub fn log(self: Util, comptime format: []const u8, args: anytype) void {
        const fp = self.filepath orelse {
            return;
        };
        const file = Io.Dir.cwd().openFile(self.init.io, fp, .{ .mode = .read_write }) catch {
            return;
        };
        // This dumb shit is required to get a mutable `self`
        var s = self;
        var file_writer = file.writer(self.init.io, &s.log_buffer);
        var writer = &file_writer.interface;
        writer.print(format, args) catch {
            return;
        };
        writer.flush() catch {};
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

    pub fn read_file(self: Util, filepath: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return try std.Io.Dir.cwd().readFileAlloc(self.init.io, filepath, allocator, .unlimited);
    }

    pub fn sleep(self: Util, seconds: i64) void {
        Io.sleep(self.init.io, .fromSeconds(seconds), .awake) catch {};
    }
};
