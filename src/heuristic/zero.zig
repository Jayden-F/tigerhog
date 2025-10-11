const std = @import("std");
const Cost = @import("../utils/cost.zig").Cost;

pub fn Zero(comptime State: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(_: *const Self, _: State, _: ?State) Cost {
            return 0;
        }
    };
}
