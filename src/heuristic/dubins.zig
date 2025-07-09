const std = @import("std");

pub fn wrap_angle(angle: f64, lower: f64, upper: f64) f64 {
    return @mod(angle - lower, upper - lower) + lower;
}

pub fn Dubins(comptime State: type) type {
    return struct {
        const Self = @This();

        radius: f64,

        pub fn init(radius: f64) Self {
            return .{
                .radius = radius,
            };
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(self: *Self, current: State, target: State) f64 {
            const x = current.get_x() - target.get_x();
            const y = current.get_y() - target.get_y();
            const theta = wrap_angle(current.get_theta() - target.get_theta(), -std.math.pi, std.math.pi);
            return @sqrt(x * x + y * y) + 2 * self.radius * std.math.sin(@abs(theta) / 2.0);
        }
    };
}
