const std = @import("std");

pub fn Manhattan(comptime State: type) type {
    return struct {
        const Self = @This();
        pub fn compute(_: *Self, current: State, target: State) f64 {
            const dx = @abs(current.get_x() - target.get_x());
            const dy = @abs(current.get_y() - target.get_y());

            const diagonals = @min(dx, dy);
            const orthoginals = @max(dx, dy) - diagonals;

            return diagonals * std.math.sqrt2() + orthoginals * 1.0;
        }
    };
}
