const std = @import("std");

pub fn Logger(comptime Node: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        writer: std.io.AnyWriter,

        fn log(self: *const Self, name: []const u8, node: *const Node) !void {
            const node_string: []const u8 = try node.to_string(self.allocator);
            defer self.allocator.free(node_string);
            try self.writer.print("  - {{ type: \"{s}\", {s} }}\n", .{ name, node_string });
        }
        pub fn init(allocator: std.mem.Allocator, writer: anytype) Self {
            return .{ .allocator = allocator, .writer = writer };
        }
        pub fn deinit(_: *Self) void {}

        pub fn initialise(self: *const Self, start: *const Node, goal: ?*const Node) !void {
            const header =
                \\version: 1.4.0
                \\views:
                \\  main:
                \\    - $: rect
                \\      width: 1
                \\      height: 1
                \\      fill: ${{{{color[$.type]}}}}
                \\      alpha: 1
                \\      x: ${{{{ $.x }}}}
                \\      y: ${{{{ $.y }}}}
                \\pivot:
                \\  x: ${{{{ $.x + 0.5 }}}}
                \\  y: ${{{{ $.y + 0.5 }}}}
                \\  scale: 1
                \\events:
                \\
            ;
            try self.writer.print(header, .{});
            try self.log("source", start);
            try self.log("destination", goal.?);
        }

        pub fn expand(self: *const Self, node: *const Node) !void {
            try self.log("expanding", node);
        }
        pub fn generate(self: *const Self, node: *const Node) !void {
            try self.log("generating", node);
        }
        pub fn close(self: *const Self, node: *const Node) !void {
            try self.log("closing", node);
        }
    };
}
