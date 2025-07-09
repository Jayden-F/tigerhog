const std = @import("std");
const direction = @import("../utils/direction.zig");

pub fn wrap_angle(angle: f64, lower: f64, upper: f64) f64 {
    return @mod(angle - lower, upper - lower) + lower;
}

pub fn HybridExpander(
    comptime Domain: type,
    comptime Node: type,
    comptime NodePool: type,
) type {
    const Edge = struct {
        state: Node.State_T,
        node: *Node,
        cost: f64,
    };

    return struct {
        const Self = @This();
        const controls = [_]struct { steering_angle: f64, distance: f64, cost: f64 }{
            .{ .steering_angle = 0, .distance = 1, .cost = 1 },
            .{ .steering_angle = -std.math.degreesToRadians(10), .distance = 1, .cost = 5 },
            .{ .steering_angle = std.math.degreesToRadians(10), .distance = 1, .cost = 5 },
            .{ .steering_angle = -std.math.degreesToRadians(10), .distance = -1, .cost = 10 },
            .{ .steering_angle = std.math.degreesToRadians(10), .distance = -1, .cost = 10 },
        };

        domain: *Domain,
        node_pool: *NodePool,

        edges: [controls.len]Edge = undefined,

        num_neighbours: usize = 0,

        pub fn init(domain: *Domain, node_pool: *NodePool) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
            };
        }

        pub fn deinit(_: *Self) void {}

        inline fn propogate(_: *const Self, state: *const Node.State_T, steering_angle: f64, distance: f64) !Node.State_T {
            const x: f64 = state.get_x();
            const y: f64 = state.get_y();
            const theta: f64 = state.get_theta();
            const curvature: f64 = @tan(steering_angle) / 1;
            const new_theta = theta + curvature * distance;

            return if (@abs(curvature) <= 1e-6) .{
                .x = x + distance * @cos(theta),
                .y = y + distance * @sin(theta),
                .theta = theta,
            } else .{
                .x = x + (@sin(new_theta) - @sin(theta)) / curvature,
                .y = y - (@cos(new_theta) - @cos(theta)) / curvature,
                .theta = wrap_angle(new_theta, -std.math.pi, std.math.pi),
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

            inline for (controls) |control| {
                const succ = try self.propogate(&current_state, control.steering_angle, control.distance);
                if (self.is_valid(succ)) {
                    try self.add_neighbour(succ, control.cost);
                }
            }

            return self.edges[0..self.num_neighbours];
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: f64) !void {
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
