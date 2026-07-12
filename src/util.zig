pub const i = @import("std").log.info;
pub const p = @import("std").log.debug;
pub const w = @import("std").log.warn;
pub const e = @import("std").log.err;
pub const l = @import("std").log.defaultLog;
pub const level = @import("std").log.Level;
pub const log = @import("std").log;
pub const io = @import("std").Io;

const std = @import("std");
const Io = std.Io;

//TODO: ALL THE LOGGING IS COMPTIME WTF
pub const Util = struct {
    init: std.process.Init,
    stderr: *io.Writer,

    // Initialize the struct; needs an Init object
    pub fn _init(init: std.process.Init, stderr: *io.Writer) Util {
        return .{
            .init = init,
            .stderr = stderr,
        };
    }

    pub fn print_prefix(self: Util, lev: level) void {
        var datetime_buf: [32]u8 = undefined;
        const pre = self.now(&datetime_buf);
        switch (lev) {
            .level.info => self.stderr.writeAll("INFO: "),
            .level.debug => self.stderr.writeAll("DEBUG: "),
            .level.warn => self.stderr.writeAll("WARN: "),
            .level.err => self.stderr.writeAll("ERROR: "),
        }
        try self.stderr.print("[{s}] ", .{pre});
        try self.stderr.flush();
    }

    pub fn info(
        self: Util,
        format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.info);
        try self.stderr.print(format, args);
        try self.stderr.flush();
    }

    pub fn debug(
        self: Util,
        format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.debug);
        try self.stderr.print(format, args);
        try self.stderr.flush();
    }

    pub fn warn(
        self: Util,
        format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.warn);
        try self.stderr.print(format, args);
        try self.stderr.flush();
    }

    pub fn err(
        self: Util,
        format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.err);
        try self.stderr.print(format, args);
        try self.stderr.flush();
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
        const day = month_day.day_index + 1; // 0-indexed to 1-indexed for the calendar day
        const day_seconds = epoch_sec_struct.getDaySeconds();
        const hour = day_seconds.getHoursIntoDay();
        const minute = day_seconds.getMinutesIntoHour();
        const second = day_seconds.getSecondsIntoMinute();

        const ret = std.fmt.bufPrint(date_time_str, "{d}-{d:02}-{d:02}T{d:02}:{d:02}:{d:02}", .{ year, month, day, hour, minute, second }) catch unreachable;
        return ret;
    }
};
