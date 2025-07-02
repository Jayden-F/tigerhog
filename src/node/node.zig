const std = @import("std");

pub fn Node(comptime State: type) type {
    return struct {
        const Self = @This();
        pub const State_T = State;

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

        pub fn default() Self {
            return .{};
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

        pub inline fn to_string(self: *const Self, allocator: std.mem.Allocator) ![]u8 {
            const node_string = try self.get_state().to_string(allocator);
            defer allocator.free(node_string);

            return try std.fmt.allocPrint(
                allocator,
                "id: {d}, pId: {?d}, g: {d}, h: {d}, f: {d}, {s}",
                .{
                    @as(u64, @bitCast(self.get_state())),
                    if (self.parent) |parent| @as(u64, @bitCast(parent.get_state())) else null,
                    self.get_g(),
                    self.get_h(),
                    self.get_f(),
                    node_string,
                },
            );
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
