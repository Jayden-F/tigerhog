const std = @import("std");
const direction = @import("../utils/direction.zig");

pub fn GridExpander4Connected(
    comptime Domain: type,
    comptime Node: type,
    comptime NodePool: type,
) type {
    const Direction = direction.Direction;
    const Neighbours = std.EnumSet(Direction);

    const Edge = struct {
        state: Node.State_T,
        node: *Node,
        cost: f64,
    };

    return struct {
        const Self = @This();
        const offsets = [_]struct { dx: i32, dy: i32, dir: direction.Direction, cost: f64 }{
            .{ .dx = 0, .dy = -1, .dir = .NORTH, .cost = 1.0 },
            .{ .dx = 1, .dy = 0, .dir = .EAST, .cost = 1.0 },
            .{ .dx = 0, .dy = 1, .dir = .SOUTH, .cost = 1.0 },
            .{ .dx = -1, .dy = 0, .dir = .WEST, .cost = 1.0 },
        };

        domain: *Domain,
        node_pool: *NodePool,
        edges: [4]Edge = undefined,
        num_neighbours: usize = 0,

        pub fn init(domain: *Domain, node_pool: *NodePool) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
            };
        }

        pub fn deinit(_: *Self) void {}

        pub inline fn get_neighbours(self: *const Self, x: i32, y: i32) Neighbours {
            var result = Neighbours.initEmpty();

            if (self.domain.is_valid(x, y - 1)) result.insert(.NORTH);

            if (self.domain.is_valid(x, y + 1)) result.insert(.SOUTH);

            if (self.domain.is_valid(x + 1, y)) result.insert(.EAST);

            if (self.domain.is_valid(x - 1, y)) result.insert(.WEST);

            return result;
        }

        pub fn expand(self: *Self, current: *const Node) ![]const Edge {
            @setRuntimeSafety(false);
            self.num_neighbours = 0;

            const current_state = current.get_state();
            const x: i32 = current_state.get_x();
            const y: i32 = current_state.get_y();

            std.debug.assert(self.domain.is_valid(x, y));

            const neighbours = self.get_neighbours(x, y);

            inline for (offsets) |offset| {
                if (neighbours.contains(offset.dir))
                    try self.add_neighbour(.{ .x = x + offset.dx, .y = y + offset.dy }, offset.cost);
            }

            return self.edges[0..self.num_neighbours];
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: f64) !void {
            @setRuntimeSafety(false);
            const node: *Node = try self.generate(state);
            self.edges[self.num_neighbours] = .{ .state = state, .node = node, .cost = cost };
            self.num_neighbours += 1;
        }

        pub inline fn generate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.generate(state);
        }

        pub inline fn reset(self: *Self) void {
            self.node_pool.reset();
        }
    };
}
