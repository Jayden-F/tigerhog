const std = @import("std");
const reverse = @import("../utils/reverse.zig");
const metrics = @import("../utils/metrics.zig");

pub fn UnidirectionalSearch(
    comptime State: type,
    comptime Node: type,
    comptime NodePool: type,
    comptime Expander: type,
    comptime Open: type,
    comptime Heuristic: type,
) type {
    return struct {
        const Self = @This();

        expander: *Expander,
        node_pool: *NodePool,
        open: *Open,
        heuristic: *Heuristic,
        metrics: metrics.Metrics,

        pub fn init(node_pool: *NodePool, expander: *Expander, open: *Open, heuristic: *Heuristic) Self {
            return .{
                .node_pool = node_pool,
                .expander = expander,
                .open = open,
                .heuristic = heuristic,
                .metrics = metrics.Metrics{},
            };
        }

        pub fn query(self: *Self, start_state: State, target_state: State) !?*Node {
            self.open.reset();
            self.node_pool.reset();
            self.metrics.reset();

            const start = std.time.nanoTimestamp();
            const target = try self.search(start_state, target_state);
            self.metrics.elapsed_time_nanos = std.time.nanoTimestamp() - start;
            if (target) |found| self.metrics.solution_cost = found.get_g();

            self.metrics.nodes_surplus = self.open.len;
            self.metrics.heap_ops = self.open.heap_ops;

            return target;
        }

        fn solution(_: *Self, target: *Node, allocator: std.mem.Allocator) ![]State {
            var array = try std.ArrayList(State).initCapacity(allocator, @intFromFloat(target.get_g()));
            var current: ?*Node = target;
            while (current) |node| {
                try array.append(node.get_state());
                current = node.get_parent();
            }

            const result = try array.toOwnedSlice();
            reverse.reverse(result);
            return result;
        }

        fn search(self: *Self, start_state: State, target_state: State) !?*Node {
            const target: *Node = try self.node_pool.generate(target_state);

            const start: *Node = try self.node_pool.generate(start_state);
            start.set_g(0.0);
            start.set_f(self.heuristic.compute(start_state, target_state));

            // std.debug.print("Start: {}\n", .{start.*});
            try self.open.push(start);

            while (!self.open.empty()) {
                const current: *Node = try self.open.pop();
                self.metrics.nodes_expanded += 1;

                // std.debug.print("Expanding: {}\n", .{current.*});

                if (current == target) {
                    return current;
                }

                for (self.expander.expand(current.get_state())) |edge| {
                    const g: f64 = current.get_g() + edge.cost;
                    const f: f64 = g + self.heuristic.compute(edge.state, target_state);

                    var successor: *Node = try self.node_pool.generate(edge.state);
                    self.metrics.nodes_generated += 1;

                    if (g < successor.get_g()) {
                        successor.set_g(g);
                        successor.set_f(f);
                        successor.set_parent(current);
                        self.open.push(successor);
                    }
                    // std.debug.print("Successor: {}\n", .{successor.*});
                }
                // std.debug.print("Closed: {}\n", .{current.*});
            }
            return null;
        }
    };
}
