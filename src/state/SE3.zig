const std = @import("std");

pub const SE3 = packed struct {
    const Self = @This();
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,
    roll: f64 = 0,
    pitch: f64 = 0,
    yaw: f64 = 0,

    pub inline fn get_x(self: *const Self) f64 {
        return self.x;
    }

    pub inline fn get_y(self: *const Self) f64 {
        return self.y;
    }

    pub inline fn get_z(self: *const Self) f64 {
        return self.z;
    }

    pub inline fn get_roll(self: *const Self) f64 {
        return self.roll;
    }

    pub inline fn get_pitch(self: *const Self) f64 {
        return self.pitch;
    }

    pub inline fn get_yaw(self: *const Self) f64 {
        return self.yaw;
    }

    pub fn format(self: *const Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        return try writer.print(
            "x: {d}, y: {d}, z: {d}, roll: {d}, pitch: {d}, yaw: {d}",
            .{ self.get_x(), self.get_y(), self.get_z(), self.get_roll(), self.get_pitch(), self.get_yaw() },
        );
    }

    pub inline fn to_id(self: *const Self) u64 {
        return std.hash.Wyhash.hash(0, std.mem.asBytes(self));
    }
};
