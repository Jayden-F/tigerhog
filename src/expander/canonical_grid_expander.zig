const std = @import("std");
const direction = @import("../utils/direction.zig");
const canonical_successors = @import("canonical_successors.zig");
const Cost = @import("../utils/cost.zig").Cost;

pub fn CanonicalGridExpander(
    comptime Domain: type,
    comptime Node: type,
    comptime NodePool: type,
) type {
    const Neighbours = canonical_successors.Neighbours;

    const Edge = struct {
        state: Node.State_T,
        node: *Node,
        cost: Cost,
    };

    return struct {
        const Self = @This();
        const offsets = canonical_successors.offsets;

        domain: *Domain,
        node_pool: *NodePool,
        edges: [8]Edge = undefined,
        num_neighbours: usize = 0,

        pub fn init(domain: *Domain, node_pool: *NodePool) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
            };
        }
        pub fn deinit(_: *Self) void {}

        pub inline fn reset(self: *Self) void {
            self.node_pool.reset();
        }

        pub fn expand(
            self: *Self,
            current: *Node,
        ) ![]const Edge {
            self.num_neighbours = 0;

            const current_state = current.get_state();
            const x: i32 = current_state.get_x();
            const y: i32 = current_state.get_y();

            std.debug.assert(self.domain.is_valid(x, y));

            const neighbours = self.get_neighbours(x, y);
            const reached_dir: ?direction.Direction = if (current.get_parent()) |parent| canonical_successors.get_reached_direction(Node, parent, current) else null;
            const successors = canonical_successors.get_successors(neighbours, reached_dir);

            inline for (offsets) |offset| {
                if (successors.contains(offset.dir))
                    try self.add_neighbour(
                        .{
                            .x = x + offset.dx,
                            .y = y + offset.dy,
                        },
                        offset.cost,
                    );
            }

            return self.edges[0..self.num_neighbours];
        }

        pub inline fn generate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.getOrCreate(state);
        }

        pub inline fn getOrCreate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.getOrCreate(state);
        }

        inline fn get_neighbours(self: *const Self, x: i32, y: i32) Neighbours {
            return canonical_successors.get_neighbours(Domain, self.domain, x, y);
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: Cost) !void {
            const node: *Node = try self.generate(state);
            self.edges[self.num_neighbours] = .{ .state = state, .node = node, .cost = cost };
            self.num_neighbours += 1;
        }
    };
}
