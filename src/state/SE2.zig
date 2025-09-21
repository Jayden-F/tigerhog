const std = @import("std");

const Self = @This();
x: f64 = 0,
y: f64 = 0,
theta: f64 = 0,

pub inline fn get_x(self: *const Self) f64 {
    return self.x;
}

pub inline fn get_y(self: *const Self) f64 {
    return self.y;
}

pub inline fn get_theta(self: *const Self) f64 {
    return self.theta;
}

pub fn format(self: *const Self, writer: *std.io.Writer) std.io.Writer.Error!void {
    return try writer.print(
        "x: {d}, y: {d}, theta: {d}",
        .{ self.get_x(), self.get_y(), self.get_theta() },
    );
}

pub inline fn to_id(self: *const Self) u64 {
    return std.hash.Wyhash.hash(0, std.mem.asBytes(self));
}
