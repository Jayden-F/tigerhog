const std = @import("std");

pub fn Node(comptime State: type) type {
    return struct {
        const Self = @This();

        state: State,
        g: f64 = std.math.inf(f64),
        f: f64 = std.math.inf(f64),
        parent: ?*Self = null,
        priority: usize = std.math.maxInt(usize),

        pub fn init(state: State, g: f64, f: f64, parent: ?*Self, priority: u64) Self {
            return .{
                .state = state,
                .g = g,
                .f = f,
                .parent = parent,
                .priority = priority,
            };
        }

        pub fn default(state: State) Self {
            return .{
                .state = state,
                .g = std.math.inf(f64),
                .f = std.math.inf(f64),
                .parent = null,
                .priority = std.math.maxInt(usize),
            };
        }

        pub inline fn set_state(self: *Self, state: State) void {
            self.state = state;
        }

        pub inline fn get_state(self: *const Self) State {
            return self.state;
        }

        pub inline fn set_g(self: *Self, g: f64) void {
            self.g = g;
        }

        pub inline fn get_g(self: *const Self) f64 {
            return self.g;
        }

        pub inline fn get_h(self: *const Self) f64 {
            return self.f - self.g;
        }

        pub inline fn set_f(self: *Self, f: f64) void {
            self.f = f;
        }

        pub inline fn get_f(self: *const Self) f64 {
            return self.f;
        }

        pub inline fn set_parent(self: *Self, parent: ?*Self) void {
            self.parent = parent;
        }

        pub inline fn get_parent(self: *const Self) ?*Self {
            return self.parent;
        }

        pub inline fn set_priority(self: *Self, priority: usize) void {
            self.priority = priority;
        }

        pub inline fn get_priority(self: *const Self) usize {
            return self.priority;
        }
    };
}

test "show size" {
    const allocator = std.testing.allocator;

    const Node_u64 = Node(u64);
    const size = @sizeOf(Node_u64);
    std.debug.print("\nsize: {}\n", .{size});

    try std.testing.expectEqual(40, size);

    const node: *Node_u64 = try allocator.create(Node_u64);
    defer allocator.destroy(node);
    node.* = Node_u64.init(
        0,
        0.0,
        0.0,
        null,
        0,
    );

    std.debug.print("node: {}\n", .{node.*});

    node.set_g(42.0);

    std.debug.print("node: {}\n", .{node.*});
}
