const std = @import("std");

pub const SE2_5 = packed struct {
    const Self = @This();
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,
    theta: f64 = 0,

    pub inline fn get_x(self: *const Self) f64 {
        return self.x;
    }

    pub inline fn get_y(self: *const Self) f64 {
        return self.y;
    }

    pub inline fn get_z(self: *const Self) f64 {
        return self.z;
    }

    pub inline fn get_theta(self: *const Self) f64 {
        return self.theta;
    }

    pub fn format(self: *const Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        return try writer.print(
            "x: {d}, y: {d}, z: {d}, theta: {d}",
            .{ self.get_x(), self.get_y(), self.get_z(), self.get_theta() },
        );
    }

    pub inline fn to_id(self: *const Self) u64 {
        return std.hash.Wyhash.hash(0, std.mem.asBytes(self));
    }
};
