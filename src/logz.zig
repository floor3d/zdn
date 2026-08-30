const std = @import("std");
pub const level = std.log.Level;
const Io = std.Io;

const red = "\x1b[31m";
const yellow = "\x1b[33m";
const cyan = "\x1b[34m";
const white = "\x1b[37m";
const reset = "\x1b[0m";

pub const Logger = struct {
    init: std.process.Init,
    stderr_buffer: [4096]u8,
    log_buffer: [4096]u8,
    stderr_writer: Io.File.Writer,
    log_writer: Io.File.Writer,
    log_file: std.Io.File,

    pub fn _init(init: std.process.Init, log_filepath: []u8) !Logger {
        var self: Logger = .{
            .init = init,
            .stderr_buffer = undefined,
            .log_buffer = undefined,
            .stderr_writer = undefined,
            .log_writer = undefined,
            .log_file = undefined,
        };
        self.stderr_writer = Io.File.stderr().writer(self.init.io, &self.stderr_buffer);
        if (log_filepath.len > 0) {
            try self.set_logger(log_filepath);
            self.log_file = try Io.Dir.cwd().openFile(self.init.io, log_filepath, .{ .mode = .read_write });
            self.log_writer = self.log_file.writer(self.init.io, &self.log_buffer);
        }
        return self;
    }

    pub fn deinit(self: *Logger) void {
        self.log_file.close(self.init.io);
    }

    fn printf(self: *Logger, comptime format: []const u8, args: anytype) void {
        const new_format = format ++ "\n";
        self.printf_no_n(new_format, args);
    }

    fn printf_no_n(self: *Logger, comptime format: []const u8, args: anytype) void {
        var writer = &self.stderr_writer.interface;
        writer.print(format, args) catch {};
        writer.flush() catch {};
        self.log(format, args) catch {};
    }

    pub fn print_prefix(self: *Logger, lev: level) void {
        var datetime_buf: [32]u8 = undefined;
        const pre = self.now(&datetime_buf);

        self.printf_no_n("[{s}] ", .{pre});
        switch (lev) {
            .info => {
                self.printf_no_n("{s}INFO:{s}  ", .{ white, reset });
            },
            .debug => {
                self.printf_no_n("{s}DEBUG:{s} ", .{ cyan, reset });
            },
            .warn => {
                self.printf_no_n("{s}WARN:{s}  ", .{ yellow, reset });
            },
            .err => {
                self.printf_no_n("{s}ERROR:{s} ", .{ red, reset });
            },
        }
    }

    pub fn set_logger(self: *Logger, filepath: []u8) !void {
        if (std.fs.path.dirname(filepath)) |dir_path| {
            try Io.Dir.cwd().createDirPath(self.init.io, dir_path);
        }
        const file = try Io.Dir.cwd().createFile(self.init.io, filepath, .{});
        file.close(self.init.io);
    }

    pub fn log(self: *Logger, comptime format: []const u8, args: anytype) !void {
        var writer = &self.log_writer.interface;
        try writer.print(format, args);
        try writer.print("{s}", .{reset});
        try writer.flush();
    }

    pub fn info(
        self: *Logger,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.info);
        self.printf(format, args);
    }

    pub fn debug(
        self: *Logger,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.debug);
        self.printf(format, args);
    }

    pub fn warn(
        self: *Logger,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.warn);
        self.printf(format, args);
    }

    pub fn err(
        self: *Logger,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.print_prefix(level.err);
        self.printf(format, args);
    }

    pub fn now(self: *Logger, date_time_str: *[32]u8) []const u8 {
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
};
