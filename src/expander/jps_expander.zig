const std = @import("std");
const direction = @import("../utils/direction.zig");
const heuristic = @import("../heuristic/mod.zig");
const canonical_successors = @import("canonical_successors.zig");
const Cost = @import("../utils/cost.zig").Cost;

pub fn JpsExpander(
    comptime Domain: type,
    comptime Node: type,
    comptime NodePool: type,
) type {
    const Edge = struct {
        state: Node.State_T,
        node: *Node,
        cost: Cost,
    };

    return struct {
        const Self = @This();

        domain: *Domain,
        node_pool: *NodePool,
        target: Node.State_T,
        edges: [8]Edge = undefined,
        num_neighbours: usize = 0,

        pub fn init(domain: *Domain, node_pool: *NodePool, target: Node.State_T) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
                .target = target,
            };
        }
        pub fn deinit(_: *Self) void {}

        pub fn expand(
            self: *Self,
            current: *Node,
        ) ![]const Edge {
            self.num_neighbours = 0;

            const current_state = current.get_state();
            const x: i32 = current_state.get_x();
            const y: i32 = current_state.get_y();

            std.debug.assert(self.domain.is_valid(x, y));

            const neighbours = canonical_successors.get_neighbours(Domain, self.domain, x, y);
            const reached_dir: ?direction.Direction = if (current.get_parent()) |parent| canonical_successors.get_reached_direction(Node, parent, current) else null;
            const successors = canonical_successors.get_successors(neighbours, reached_dir);

            const all_dirs = [_]direction.Direction{ .NORTH, .EAST, .SOUTH, .WEST, .NORTH_EAST, .SOUTH_EAST, .SOUTH_WEST, .NORTH_WEST };
            inline for (all_dirs) |dir| {
                if (successors.contains(dir)) {
                    if (self.jump(current_state, dir)) |jump_state| {
                        const cost = heuristic.Octile(Node.State_T).init().compute(current_state, jump_state);
                        try self.add_neighbour(jump_state, cost);
                    }
                }
            }

            return self.edges[0..self.num_neighbours];
        }

        fn jump(self: *Self, start: Node.State_T, dir: direction.Direction) ?Node.State_T {
            const dx: i32 = switch (dir) {
                .NORTH => 0,
                .EAST => 1,
                .SOUTH => 0,
                .WEST => -1,
                .NORTH_EAST => 1,
                .SOUTH_EAST => 1,
                .SOUTH_WEST => -1,
                .NORTH_WEST => -1,
            };
            const dy: i32 = switch (dir) {
                .NORTH => -1,
                .EAST => 0,
                .SOUTH => 1,
                .WEST => 0,
                .NORTH_EAST => -1,
                .SOUTH_EAST => 1,
                .SOUTH_WEST => 1,
                .NORTH_WEST => -1,
            };

            var cx = start.get_x() + dx;
            var cy = start.get_y() + dy;

            while (self.domain.is_valid(cx, cy)) {
                const current = Node.State_T{ .x = cx, .y = cy };

                // Check if goal
                if (cx == self.target.get_x() and cy == self.target.get_y()) {
                    return current;
                }

                // Check if forced
                if (self.has_forced(cx, cy, dir)) {
                    return current;
                }

                // For diagonal, check cardinal jumps
                if (dx != 0 and dy != 0) {
                    if (self.jump(current, if (dx > 0) .EAST else .WEST)) |_| return current;
                    if (self.jump(current, if (dy > 0) .SOUTH else .NORTH)) |_| return current;
                }

                cx += dx;
                cy += dy;
            }

            return null;
        }

        fn has_forced(self: *Self, x: i32, y: i32, dir: direction.Direction) bool {
            return switch (dir) {
                .NORTH => (!self.domain.is_valid(x - 1, y + 1) and self.domain.is_valid(x - 1, y)) or
                    (!self.domain.is_valid(x + 1, y + 1) and self.domain.is_valid(x + 1, y)),
                .NORTH_EAST => false,
                .EAST => (!self.domain.is_valid(x - 1, y - 1) and self.domain.is_valid(x, y - 1)) or
                    (!self.domain.is_valid(x - 1, y + 1) and self.domain.is_valid(x, y + 1)),
                .SOUTH_EAST => false,
                .SOUTH => (!self.domain.is_valid(x - 1, y - 1) and self.domain.is_valid(x - 1, y)) or
                    (!self.domain.is_valid(x + 1, y - 1) and self.domain.is_valid(x + 1, y)),
                .SOUTH_WEST => false,
                .WEST => (!self.domain.is_valid(x + 1, y - 1) and self.domain.is_valid(x, y - 1)) or
                    (!self.domain.is_valid(x + 1, y + 1) and self.domain.is_valid(x, y + 1)),
                .NORTH_WEST => false,
            };
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: Cost) !void {
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
