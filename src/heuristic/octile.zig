const std = @import("std");

pub fn Octile(comptime State: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(_: *const Self, current: State, target: ?State) f64 {
            const dx: f64 = @floatFromInt(@abs(current.get_x() - target.?.get_x()));
            const dy: f64 = @floatFromInt(@abs(current.get_y() - target.?.get_y()));

            const diagonals = @min(dx, dy);
            const orthoginals = @max(dx, dy) - diagonals;

            return diagonals * std.math.sqrt2 + orthoginals * 1.0;
        }
    };
}
