const std = @import("std");

pub fn NoopLogger(comptime Node: type) type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}
        pub fn flush(_: *Self) !void {}

        pub fn initialise(_: *const Self, _: *const Node, _: ?*const Node) !void {}
        pub fn expand(_: *const Self, _: *const Node) !void {}
        pub fn generate(_: *const Self, _: *const Node) !void {}
        pub fn close(_: *const Self, _: *const Node) !void {}
    };
}
