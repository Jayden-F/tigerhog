const std = @import("std");
const angles = @import("../utils/angles.zig");

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

        pub fn compute(self: *Self, current: State, target: ?State) f64 {
            const x = current.get_x() - target.?.get_x();
            const y = current.get_y() - target.?.get_y();
            const theta = angles.wrap(f64, current.get_theta() - target.?.get_theta(), -std.math.pi, std.math.pi);
            return @sqrt(x * x + y * y) + 2 * self.radius * std.math.sin(@abs(theta) / 2.0);
        }
    };
}
