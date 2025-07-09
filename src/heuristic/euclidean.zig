const std = @import("std");

pub fn Euclidean(comptime State: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(_: *Self, current: State, target: State) f64 {
            const x = current.get_x() - target.get_x();
            const y = current.get_y() - target.get_y();
            return @sqrt(x * x + y * y);
        }
    };
}
