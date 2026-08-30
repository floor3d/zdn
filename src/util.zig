const std = @import("std");
const Io = std.Io;

pub const Util = struct {
    init: std.process.Init,

    pub fn _init(init: std.process.Init) !Util {
        return .{
            .init = init,
        };
    }

    pub fn read_file(self: Util, filepath: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return try std.Io.Dir.cwd().readFileAlloc(self.init.io, filepath, allocator, .unlimited);
    }

    pub fn sleep(self: Util, seconds: i64) void {
        Io.sleep(self.init.io, .fromSeconds(seconds), .awake) catch {};
    }
};
