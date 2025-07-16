const std = @import("std");

const Self = @This();
x: f64,
y: f64,
theta: f64,

pub inline fn get_x(self: *const Self) f64 {
    return self.x;
}

pub inline fn get_y(self: *const Self) f64 {
    return self.y;
}

pub inline fn get_theta(self: *const Self) f64 {
    return self.theta;
}

pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    return try writer.print(
        "x: {d}, y: {d}, theta: {d}",
        .{ self.get_x(), self.get_y(), self.get_theta() },
    );
}

pub inline fn to_id(self: *const Self) u64 {
    return std.hash.Wyhash.hash(0, std.mem.asBytes(self));
}
