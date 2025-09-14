const std = @import("std");

pub fn Manhattan(comptime State: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        pub fn deinit(_: *Self) void {}

        pub inline fn compute(_: *Self, current: State, target: ?State) f64 {
            const x_diff = @abs(current.get_x() - target.?.get_x());
            const y_diff = @abs(current.get_y() - target.?.get_y());
            return @floatFromInt(x_diff + y_diff);
        }
    };
}
