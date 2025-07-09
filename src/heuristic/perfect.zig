const std = @import("std");

pub fn Perfect(
    comptime State: type,
    comptime Domain: type,
    comptime NodePool: type,
    comptime Expander: type,
) type {
    return struct {
        const Self = @This();

        domain: *Domain,
        node_pool: NodePool,
        expander: Expander,

        search:

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn compute(_: *Self, current: State, target: State) f64 {
        }
    };
}
