const std = @import("std");

pub fn Zero(comptime State: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(_: *Self, _: State, _: ?State) f64 {
            return 0;
        }
    };
}
