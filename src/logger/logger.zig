const std = @import("std");

pub fn Logger(comptime Node: type) type {
    return struct {
        const Self = @This();

        writer: *std.io.Writer,

        fn log(self: *Self, name: []const u8, node: *const Node) !void {
            try self.writer.print("  - {{ type: \"{s}\", {f} }}\n", .{ name, node });
        }

        pub fn init(writer: *std.io.Writer) Self {
            return .{ .writer = writer };
        }

        pub fn flush(self: *Self) !void {
            try self.writer.flush();
        }

        pub fn deinit(_: *Self) void {}

        pub fn initialise(self: *Self, start: *const Node, goal: ?*const Node) !void {
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

        pub fn expand(self: *Self, node: *const Node) !void {
            try self.log("expanding", node);
        }
        pub fn generate(self: *Self, node: *const Node) !void {
            try self.log("generating", node);
        }
        pub fn close(self: *Self, node: *const Node) !void {
            try self.log("closing", node);
        }
    };
}
