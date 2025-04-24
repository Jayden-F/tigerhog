const std = @import("std");

pub fn Node(comptime State: type) type {
    return struct {
        const Self = @This();
        pub const Status = enum(u1) { Open, Closed };

        state: State,
        g: f64 = 0.0,
        f: f64 = 0.0,
        parent: ?*Self = null,
        status: Status = Status.Open,
        priority: ?u64 = null,
        search_number: u64 = 0,

        pub fn init(state: State, g: f64, f: f64, parent: ?*Self, status: Status, priority: u64, search_number: u64) Self {
            return .{
                .state = state,
                .g = g,
                .f = f,
                .parent = parent,
                .status = status,
                .priority = priority,
                .search_number = search_number,
            };
        }

        pub fn default(state: State) Self {
            return .{
                .state = state,
                .g = 0.0,
                .f = 0.0,
                .parent = null,
                .status = Status.Open,
                .priority = null,
                .search_number = 0,
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

        pub inline fn set_status(self: *Self, status: Status) void {
            self.status = status;
        }

        pub inline fn get_status(self: *const Self) Status {
            return self.status;
        }

        pub inline fn set_priority(self: *Self, priority: ?u64) void {
            self.priority = priority;
        }

        pub inline fn get_priority(self: *const Self) ?u64 {
            return self.priority;
        }

        pub inline fn set_search_number(self: *Self, search_number: u64) void {
            self.search_number = search_number;
        }

        pub inline fn get_search_number(self: *const Self) ?u64 {
            return self.search_number;
        }
    };
}

test "show size" {
    const allocator = std.testing.allocator;

    const Node_u64 = Node(u64);
    const size = @sizeOf(Node_u64);
    std.debug.print("\nsize: {}\n", .{size});

    try std.testing.expectEqual(64, size);

    const node: *Node_u64 = try allocator.create(Node_u64);
    defer allocator.destroy(node);
    node.* = Node_u64.init(0, 0.0, 0.0, null, Node_u64.Status.Closed, 0, 0);

    std.debug.print("node: {}\n", .{node.*});

    node.set_g(42.0);

    std.debug.print("node: {}\n", .{node.*});
}
