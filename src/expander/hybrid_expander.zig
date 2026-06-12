const std = @import("std");
const angles = @import("../utils/angles.zig");
const Cost = @import("../utils/cost.zig").Cost;

pub fn HybridExpander(
    comptime Domain: type,
    comptime Node: type,
    comptime NodePool: type,
    comptime turn_radius: f64,
) type {
    comptime {
        if (!(turn_radius > 0.0)) {
            @compileError("HybridExpander turn_radius must be greater than zero");
        }
    }

    const Edge = struct {
        state: Node.State_T,
        node: *Node,
        cost: Cost,
    };

    return struct {
        const Self = @This();

        pub const action_length: f64 = 1.0;
        pub const configured_turn_radius: f64 = turn_radius;

        pub const Straight = struct {
            length: f64,
        };

        pub const CircularArc = struct {
            /// Signed radius. Positive turns left, negative turns right.
            radius: f64,
            length: f64,
        };

        pub const Action = union(enum) {
            straight: Straight,
            circular_arc: CircularArc,

            pub inline fn cost(action: Action) Cost {
                return switch (action) {
                    .straight => |straight| straight.length,
                    .circular_arc => |arc| arc.length,
                };
            }
        };

        pub const actions = [_]Action{
            .{ .circular_arc = .{ .radius = configured_turn_radius, .length = action_length } },
            .{ .straight = .{ .length = action_length } },
            .{ .circular_arc = .{ .radius = -configured_turn_radius, .length = action_length } },
        };
        pub const N = actions.len;

        domain: *Domain,
        node_pool: *NodePool,

        edges: [N]Edge = undefined,

        num_neighbours: usize = 0,

        pub fn init(domain: *Domain, node_pool: *NodePool) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
            };
        }

        pub fn deinit(_: *Self) void {}

        pub fn propagate(state: *const Node.State_T, action: Action) Node.State_T {
            return switch (action) {
                .straight => |straight| propagate_straight(state, straight),
                .circular_arc => |arc| propagate_arc(state, arc),
            };
        }

        fn propagate_straight(state: *const Node.State_T, straight: Straight) Node.State_T {
            const theta = state.get_theta();
            return .{
                .x = state.get_x() + straight.length * @cos(theta),
                .y = state.get_y() + straight.length * @sin(theta),
                .theta = theta,
            };
        }

        fn propagate_arc(state: *const Node.State_T, arc: CircularArc) Node.State_T {
            const theta = state.get_theta();
            const heading_delta = arc.length / arc.radius;
            const next_theta = theta + heading_delta;

            return .{
                .x = state.get_x() + arc.radius * (@sin(next_theta) - @sin(theta)),
                .y = state.get_y() + arc.radius * (@cos(theta) - @cos(next_theta)),
                .theta = next_theta,
            };
        }

        inline fn is_valid(self: *Self, state: Node.State_T) bool {
            const x: i32 = @intFromFloat(state.get_x());
            const y: i32 = @intFromFloat(state.get_y());
            return self.domain.is_valid(x, y);
        }

        pub fn expand(self: *Self, current: *const Node) ![]const Edge {
            self.num_neighbours = 0;

            const current_state: Node.State_T = current.get_state();
            std.debug.assert(self.is_valid(current_state));

            inline for (actions) |action| {
                var next_state = propagate(&current_state, action);
                next_state.theta = angles.wrap(f64, next_state.theta, -std.math.pi, std.math.pi);

                if (self.is_valid(next_state)) {
                    try self.add_neighbour(next_state, action.cost());
                }
            }

            return self.edges[0..self.num_neighbours];
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: Cost) !void {
            const node: *Node = try self.generate(state);
            self.edges[self.num_neighbours] = .{ .state = state, .node = node, .cost = cost };
            self.num_neighbours += 1;
        }

        pub inline fn generate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.getOrCreate(state);
        }

        pub inline fn getOrCreate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.getOrCreate(state);
        }

        pub inline fn reset(self: *Self) void {
            self.node_pool.reset();
        }
    };
}
