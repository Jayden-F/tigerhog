const std = @import("std");
const Cost = @import("../utils/cost.zig").Cost;

pub fn Euclidean(comptime State: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(_: *const Self, current: State, target: State) Cost {
            const x = current.get_x() - target.get_x();
            const y = current.get_y() - target.get_y();
            return @sqrt(x * x + y * y);
        }
    };
}
