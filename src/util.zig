pub const i = @import("std").log.info;
pub const p = @import("std").log.debug;
pub const w = @import("std").log.warn;
pub const e = @import("std").log.err;
const std = @import("std");

pub fn info(
    comptime format: []const u8,
    args: anytype,
) void {
    const datetime_buf: [32]u8 = undefined;
    const pre = now(&datetime_buf);
    const msg = pre ++ " " ++ format;
    i(msg, args);
}

pub fn now(date_time_str: *const [32]u8) []const u8 {
    // Fetch the current Unix timestamp structure
    // TODO: Add state somehow; make an init() that `main` calls to garner that got damn Init struct
    const n = std.Io.Clock.real.now(std.process.Init.io);
    const epoch_seconds: i64 = n.seconds;
    const epoch_day: i64 = @divFloor(epoch_seconds, std.time.s_per_day);
    const second_in_day: i32 = @intCast(@mod(epoch_seconds, std.time.s_per_day));
    const year_info = std.time.epoch.epochDaysToYear(epoch_day);
    const month_day = std.time.epoch.getYearMonthDay(year_info.day_of_year, year_info.year);
    const hour = @divFloor(second_in_day, std.time.s_per_hour);
    const min = @divFloor(@mod(second_in_day, std.time.s_per_hour), std.time.s_per_min);
    const sec = @mod(second_in_day, std.time.s_per_min);
    const ret = try std.fmt.bufPrint(date_time_str, "{d}-{d:02}-{d:02}T{d:02}:{d:02}:{d:02}Z", .{ year_info.year, month_day.month, month_day.day, hour, min, sec });
    return ret;
}
