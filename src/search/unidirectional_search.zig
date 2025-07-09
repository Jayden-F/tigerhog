const std = @import("std");
const reverse = @import("../utils/reverse.zig");
const metrics = @import("../utils/metrics.zig");

pub fn UnidirectionalSearch(
    comptime State: type,
    comptime Node: type,
    comptime Expander: type,
    comptime Open: type,
    comptime Heuristic: type,
    comptime Logger: type,
) type {
    return struct {
        const Self = @This();

        expander: *Expander,
        open: *Open,
        heuristic: *Heuristic,
        logger: *Logger,
        metrics: metrics.Metrics,

        pub fn init(
            expander: *Expander,
            open: *Open,
            heuristic: *Heuristic,
            logger: *Logger,
        ) Self {
            return .{
                .expander = expander,
                .open = open,
                .heuristic = heuristic,
                .logger = logger,
                .metrics = metrics.Metrics{},
            };
        }

        pub fn deinit(_: *Self) void {}

        pub fn query(self: *Self, start_state: State, target_state: State) !?*const Node {
            const timestamp_nanos = std.time.nanoTimestamp();
            const target: ?*const Node = try self.search(start_state, target_state);
            self.metrics.elapsed_time_nanos = std.time.nanoTimestamp() - timestamp_nanos;
            if (target) |found| self.metrics.solution_cost = found.get_g();

            self.metrics.nodes_surplus = self.open.len;
            self.metrics.heap_ops = self.open.heap_ops;

            return target;
        }

        pub fn reset(self: *Self) void {
            self.open.reset();
            self.expander.reset();
            self.metrics.reset();
        }

        pub fn get_metrics(self: *const Self) *const metrics.Metrics {
            return &self.metrics;
        }

        pub fn solution(_: *const Self, target: *const Node, allocator: std.mem.Allocator) ![]State {
            var array = try std.ArrayList(State).initCapacity(allocator, @intFromFloat(target.get_g()));
            var current: ?*const Node = target;
            while (current) |node| {
                try array.append(node.get_state());
                current = node.get_parent();
            }

            const result = try array.toOwnedSlice();
            reverse.reverse(result);
            return result;
        }

        fn search(self: *Self, start_state: State, target_state: State) !?*const Node {
            const target: *Node = try self.expander.generate(target_state);
            const start: *Node = try self.expander.generate(start_state);

            start.set_g(0.0);
            start.set_f(self.heuristic.compute(start_state, target_state));

            try self.open.push(start);
            try self.logger.initialise(start, target);

            while (!self.open.empty()) {
                const current: *Node = try self.open.pop();
                self.metrics.nodes_expanded += 1;
                try self.logger.expand(current);
                // @floor(current.get_state().get_x()) == @floor(target.get_state().get_x()) and @floor(current.get_state().get_y()) == @floor(target.get_state().get_y())
                if (current == target) {
                    return current;
                }

                for (try self.expander.expand(current)) |*edge| {
                    const successor: *Node = edge.node;
                    const g: f64 = current.get_g() + edge.cost;

                    if (g < successor.get_g()) {
                        successor.set_state(edge.state);
                        successor.set_parent(current);
                        successor.set_g(g);
                        const f: f64 = g + self.heuristic.compute(successor.get_state(), target_state);
                        successor.set_f(f);

                        try self.open.push(successor);
                        try self.logger.generate(successor);
                        self.metrics.nodes_generated += 1;
                    }
                }

                try self.logger.close(current);
            }
            return null;
        }
    };
}
