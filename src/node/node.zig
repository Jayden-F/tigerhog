const std = @import("std");
const states = @import("../state/mod.zig");
const Cost = @import("../utils/cost.zig").Cost;

pub fn Node(comptime State: type) type {
    return struct {
        const Self = @This();
        pub const State_T = State;

        state: State = .{},
        g: Cost = std.math.inf(Cost),
        f: Cost = std.math.inf(Cost),
        parent: ?*Self = null,
        priority: usize = std.math.maxInt(usize),

        pub inline fn set_state(self: *Self, state: State) void {
            self.state = state;
        }

        pub inline fn get_state(self: *const Self) State {
            return self.state;
        }

        pub inline fn set_g(self: *Self, g: Cost) void {
            self.g = g;
        }

        pub inline fn get_g(self: *const Self) Cost {
            return self.g;
        }

        pub inline fn get_h(self: *const Self) Cost {
            return self.f - self.g;
        }

        pub inline fn set_f(self: *Self, f: Cost) void {
            self.f = f;
        }

        pub inline fn get_f(self: *const Self) Cost {
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

        pub fn format(self: *const Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
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
    std.debug.print("\n", .{});

    const allocator = std.testing.allocator;
    const NodeType = Node(states.State);

    const size = @sizeOf(NodeType);
    std.debug.print("size: {}\n", .{size});

    try std.testing.expectEqual(40, size);

    const node: *NodeType = try allocator.create(NodeType);
    defer allocator.destroy(node);
    node.* = .{};

    std.debug.print("node: {f}\n", .{node.*});

    node.set_g(42.0);

    std.debug.print("node: {f}\n", .{node.*});
}
