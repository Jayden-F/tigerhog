const std = @import("std");

pub fn Logger(comptime Node: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        writer: std.io.AnyWriter,

        fn log(self: *const Self, name: []const u8, node: *const Node) !void {
            const node_string: []const u8 = try node.to_string(self.allocator);
            defer self.allocator.free(node_string);
            std.debug.print("  -type: {s}, {s}\n", .{ name, node_string });
        }
        pub fn init(allocator: std.mem.Allocator, writer: anytype) Self {
            return .{ .allocator = allocator, .writer = writer };
        }
        pub fn deinit(_: *Self) void {}

        pub fn initialise(_: *const Self, _: *const Node, _: *const Node) !void {}

        pub fn expand(self: *const Self, node: *const Node) !void {
            try self.log("expand", node);
        }
        pub fn generate(self: *const Self, node: *const Node) !void {
            try self.log("generate", node);
        }
        pub fn close(self: *const Self, node: *const Node) !void {
            try self.log("close", node);
        }
    };
}
