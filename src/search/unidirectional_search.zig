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
        search_number: usize = 0,
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
            self.search_number += 1;
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
            start.set_search_number(self.search_number);

            // std.debug.print("Start: {}\n", .{start.*});
            try self.open.push(start);

            while (!self.open.empty()) {
                const current: *Node = try self.open.pop();
                current.set_status(Node.Status.Closed);
                self.metrics.nodes_expanded += 1;

                // std.debug.print("Expanding: {}\n", .{current.*});

                if (current == target) {
                    return current;
                }

                for (self.expander.expand(current.get_state())) |edge| {
                    var successor: *Node = try self.node_pool.generate(edge.state);

                    self.metrics.nodes_generated += 1;

                    const g: f64 = current.get_g() + edge.cost;
                    const f: f64 = g + self.heuristic.compute(edge.state, target_state);

                    if (successor.get_search_number() != current.get_search_number()) {
                        successor.set_search_number(self.search_number);
                        successor.set_state(edge.state);
                        successor.set_g(g);
                        successor.set_f(f);
                        successor.set_parent(current);
                        try self.open.push(successor);
                    } else {
                        if (g < successor.get_g()) {
                            successor.set_g(g);
                            successor.set_f(f);

                            switch (successor.get_status()) {
                                Node.Status.Closed => {
                                    successor.set_status(Node.Status.Open);
                                    try self.open.push(successor);
                                    self.metrics.nodes_reopened += 1;
                                },
                                Node.Status.Open => self.open.decrease_key(successor),
                            }
                        }
                    }
                    // std.debug.print("Successor: {}\n", .{successor.*});
                }
                // std.debug.print("Closed: {}\n", .{current.*});
            }
            return null;
        }
    };
}
