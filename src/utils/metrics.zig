pub const Metrics = struct {
    const Self = @This();

    nodes_expanded: usize = 0,
    nodes_generated: usize = 0,
    nodes_reopened: usize = 0,
    nodes_surplus: usize = 0,
    solution_cost: f64 = 0,
    heap_ops: usize = 0,
    elapsed_time_nanos: i128 = 0,

    pub fn reset(self: *Self) void {
        self.* = Metrics{};
    }
};
