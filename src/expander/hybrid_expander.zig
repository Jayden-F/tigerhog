const std = @import("std");
const direction = @import("../utils/direction.zig");
const angles = @import("../utils/angles.zig");
const Cost = @import("../utils/cost.zig").Cost;

pub fn HybridExpander(
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

        pub const N = 6;
        pub const Nxf64 = @Vector(N, f64);

        pub const ControlBatch = struct {
            steering_angle: Nxf64,
            distance: Nxf64,
            cost: Nxf64,
        };

        const turn_radius: f64 = std.math.degreesToRadians(10);

        const control_batch = ControlBatch{
            .steering_angle = .{
                0.0, -turn_radius, turn_radius,
                0.0, -turn_radius, turn_radius,
            },
            .distance = .{
                1.0,  1.0,  1.0,
                -1.0, -1.0, -1.0,
            },
            .cost = .{
                1.0,  1.05, 1.05,
                1.25, 1.25, 1.25,
            },
        };

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

        pub const StateBatch = struct {
            x: Nxf64,
            y: Nxf64,
            theta: Nxf64,
        };

        pub fn propagate_many(
            state: *const Node.State_T,
            steering_angles: Nxf64,
            distances: Nxf64,
        ) StateBatch {
            const x: Nxf64 = @splat(state.get_x());
            const y: Nxf64 = @splat(state.get_y());
            const theta: Nxf64 = @splat(state.get_theta());

            const curvature = @tan(steering_angles);
            const new_theta = theta + curvature * distances;

            const epsilon: Nxf64 = comptime @splat(1e-6);
            const is_straight = @abs(curvature) <= epsilon;

            const sin_theta = @sin(theta);
            const cos_theta = @cos(theta);
            const sin_new = @sin(new_theta);
            const cos_new = @cos(new_theta);

            const x_straight = x + distances * cos_theta;
            const y_straight = y + distances * sin_theta;

            const x_arc = x + (sin_new - sin_theta) / curvature;
            const y_arc = y + (cos_theta - cos_new) / curvature;

            const out_x = @select(f64, is_straight, x_straight, x_arc);
            const out_y = @select(f64, is_straight, y_straight, y_arc);

            return .{
                .x = out_x,
                .y = out_y,
                .theta = new_theta, // Keep unwrapped for now
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

            const batch = propagate_many(&current_state, control_batch.steering_angle, control_batch.distance);

            var i: usize = 0;
            while (i < N) : (i += 1) {
                const x_i = batch.x[i];
                const y_i = batch.y[i];
                const theta_i = angles.wrap(f64, batch.theta[i], -std.math.pi, std.math.pi);

                const x_cell: i32 = @intFromFloat(x_i);
                const y_cell: i32 = @intFromFloat(y_i);
                if (self.domain.is_valid(x_cell, y_cell)) {
                    try self.add_neighbour(.{
                        .x = x_i,
                        .y = y_i,
                        .theta = theta_i,
                    }, control_batch.cost[i]);
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
