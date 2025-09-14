const std = @import("std");

pub const Metrics = struct {
    const Self = @This();

    nodes_expanded: usize = 0,
    nodes_generated: usize = 0,
    nodes_surplus: usize = 0,
    solution_cost: f64 = std.math.inf(f64),
    heap_ops: usize = 0,
    elapsed_time_nanos: i128 = 0,

    pub fn reset(self: *Self) void {
        self.* = Metrics{};
    }

    pub fn format(self: *const Self, writer: *std.io.Writer) std.io.Writer.Error!void {
        return try writer.print(
            "Metrics{{ .nodes_expanded = {}, .nodes_generated = {}, .nodes_surplus = {}, .solution_cost = {d}, .heap_ops = {}, .elapsed_time_nanos = {} }}",
            .{
                self.nodes_expanded,
                self.nodes_generated,
                self.nodes_surplus,
                self.solution_cost,
                self.heap_ops,
                self.elapsed_time_nanos,
            },
        );
    }
};
