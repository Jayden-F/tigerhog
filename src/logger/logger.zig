const std = @import("std");

pub fn Logger(comptime Node: type) type {
    return struct {
        const Self = @This();

        fn log(_: *const Self, name: []const u8, node: *const Node) void {
            std.debug.print("{s} {}\n", .{ name, node.get_state() });
        }
        pub fn init() Self {
            return .{};
        }
        pub fn deinit(_: *Self) void {}

        pub fn initialise(_: *const Self, _: *const Node, _: *const Node) void {}

        pub fn expand(self: *const Self, node: *const Node) void {
            self.log("expand", node);
        }
        pub fn generate(self: *const Self, node: *const Node) void {
            self.log("generate", node);
        }
        pub fn close(self: *const Self, node: *const Node) void {
            self.log("close", node);
        }
    };
}
