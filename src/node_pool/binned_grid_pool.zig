const std = @import("std");
const grid_pool = @import("./grid_pool.zig");

pub fn BinnedGridPool(comptime State: type, comptime Node: type) type {
    return struct {
        const Self = @This();

        const num_bins: usize = 36;
        grid_pools: std.array_list.Managed(grid_pool.GridPool(State, Node)),

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            var grid_pools = std.array_list.Managed(grid_pool.GridPool(State, Node)).init(allocator);

            for (0..num_bins) |_| {
                try grid_pools.append(try grid_pool.GridPool(State, Node).init(width, height, allocator));
            }

            return .{
                .grid_pools = grid_pools,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.grid_pools.items) |*pool| {
                pool.deinit();
            }
            self.grid_pools.deinit();
        }

        fn get_bin(_: *Self, state: State) !usize {
            const theta: f64 = state.get_theta();
            const bin = @floor((theta / comptime std.math.degreesToRadians(10)) + num_bins / 2);
            const result: usize = @intFromFloat(bin);
            return result;
        }

        pub inline fn generate(self: *Self, state: State) !*Node {
            const bin = try self.get_bin(state);
            const node = try self.grid_pools.items[bin].generate(state);
            return node;
        }

        pub fn reset(self: *Self) void {
            for (self.grid_pools.items) |*pool| {
                pool.reset();
            }
        }
    };
}
