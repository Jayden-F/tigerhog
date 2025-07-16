const std = @import("std");

pub fn PathLogger(comptime State: type) type {
    return struct {
        const Self = @This();

        writer: std.io.AnyWriter,

        pub fn init(writer: anytype) Self {
            return .{ .writer = writer };
        }

        fn log(self: *const Self, name: []const u8, state: State, id: usize, pId: ?usize) !void {
            try self.writer.print("  - {{ type: \"{s}\", {}, id: \"{d}\", pId: \"{?d}\" }}\n", .{
                name,
                state,
                id,
                pId,
            });
        }

        pub fn deinit(_: *Self) void {}

        fn initialise(self: *const Self) !void {
            const header =
                \\version: 1.4.0
                \\views:
                \\  main:
                \\    - $: circle
                \\      radius: 0.125
                \\      fill: ${{{{color[$.type]}}}}
                \\      alpha: 1
                \\      x: ${{{{ $.x }}}}
                \\      y: ${{{{ $.y }}}}
                \\pivot:
                \\  x: ${{{{ $.x }}}}
                \\  y: ${{{{ $.y }}}}
                \\  scale: 0.25
                \\events:
                \\
            ;
            try self.writer.print(header, .{});
        }

        pub fn log_path(self: *const Self, path: []const State) !void {
            var pId: ?usize = null;
            try self.initialise();

            for (path, 0..) |state, id| {
                try self.log("closing", state, id, pId);
                pId = id;
            }
        }
    };
}
