const std = @import("std");

pub const State = packed struct {
    const Self = @This();
    x: i32 = 0,
    y: i32 = 0,

    pub inline fn get_x(self: *const Self) i32 {
        return self.x;
    }

    pub inline fn get_y(self: *const Self) i32 {
        return self.y;
    }

    pub fn format(self: *const Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("x: {d}, y: {d}", .{ self.get_x(), self.get_y() });
    }

    pub inline fn to_id(self: *const Self) u64 {
        return @as(u64, @bitCast(self.*));
    }
};
