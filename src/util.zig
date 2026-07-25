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
// const c = @import("c");

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

    // fn printf(format: [*c]const u8, args: anytype) void {
    //     const all_args = .{format} ++ args;
    //     _ = @call(.auto, c.printf, all_args);
    // }
    //
    // pub fn print_prefix(self: Util, lev: level) void {
    //     var datetime_buf: [32]u8 = undefined;
    //
    //     const lev_str = switch (lev) {
    //         .err => "error",
    //         .warn => "warning",
    //         .info => "info",
    //         .debug => "debug",
    //     };
    //     const pre = self.now(&datetime_buf);
    //     _ = c.printf(
    //         "[%s] [%.*s] ",
    //         pre,
    //         @as(c_int, @intCast(lev_str.len)),
    //         lev_str.ptr,
    //     );
    // }
    //
    // pub fn info(
    //     self: Util,
    //     format: [*c]const u8,
    //     args: anytype,
    // ) void {
    //     self.print_prefix(level.info);
    //     printf(format, args);
    // }
    //
    // pub fn debug(
    //     self: Util,
    //     format: [*c]const u8,
    //     args: anytype,
    // ) void {
    //     self.print_prefix(level.debug);
    //     printf(format, args);
    // }
    //
    // pub fn warn(
    //     self: Util,
    //     format: [*c]const u8,
    //     args: anytype,
    // ) void {
    //     self.print_prefix(level.warn);
    //     printf(format, args);
    // }
    //
    // pub fn err(
    //     self: Util,
    //     format: [*c]const u8,
    //     args: anytype,
    // ) void {
    //     self.print_prefix(level.err);
    //     printf(format, args);
    // }
    //
    // pub fn now(self: Util, date_time_str: *[32]u8) [*c]const u8 {
    //     const t = Io.Clock.real.now(self.init.io);
    //     const n: u64 = @as(u64, @intCast(t.toSeconds()));
    //     const epoch_sec_struct = std.time.epoch.EpochSeconds{ .secs = n };
    //     const epoch_day = epoch_sec_struct.getEpochDay();
    //     const year_and_day = epoch_day.calculateYearDay();
    //     const year = year_and_day.year;
    //     const month_day = year_and_day.calculateMonthDay();
    //     const month = @as(i32, @intCast(month_day.month.numeric()));
    //     const day = @as(i32, @intCast(month_day.day_index + 1)); // 0-indexed to 1-indexed for the calendar day
    //     const day_seconds = epoch_sec_struct.getDaySeconds();
    //     const hour = @as(i32, @intCast(day_seconds.getHoursIntoDay()));
    //     const minute = @as(i32, @intCast(day_seconds.getMinutesIntoHour()));
    //     const second = @as(i32, @intCast(day_seconds.getSecondsIntoMinute()));
    //
    //     _ = c.sprintf(date_time_str, "%d-%02d-%02dT%02d:%02d:%02d", year, month, day, hour, minute, second);
    //     return date_time_str;
    // }
};
