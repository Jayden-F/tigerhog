const std = @import("std");
const states = @import("../state/mod.zig");

pub fn Node(comptime State: type) type {
    return struct {
        const Self = @This();
        pub const State_T = State;

        state: State = .{},
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

        pub fn format(self: *const Self, writer: *std.io.Writer) std.io.Writer.Error!void {
            return try writer.print(
                "id: {}, {f}, g: {d}, f: {d}, parent: {?}, priority: {d}",
                .{
                    self.state.to_id(),
                    self.state,
                    self.g,
                    self.f,
                    if (self.parent) |p| p.state.to_id() else null,
                    self.priority,
                },
            );
        }

        pub fn lessThanFn(self: *const Self, other: *const Self) bool {
            if (self.get_f() < other.get_f()) return true;
            if (self.get_f() > other.get_f()) return false;
            return self.get_g() > other.get_g();
        }
    };
}

test "show size" {
    const allocator = std.testing.allocator;

    const NodeType = Node(states.State);

    const size = @sizeOf(NodeType);
    std.debug.print("\nsize: {}\n", .{size});

    try std.testing.expectEqual(40, size);

    const node: *NodeType = try allocator.create(NodeType);
    defer allocator.destroy(node);
    node.* = .{};

    std.debug.print("node: {f}\n", .{node.*});

    node.set_g(42.0);

    std.debug.print("node: {f}\n", .{node.*});
}
