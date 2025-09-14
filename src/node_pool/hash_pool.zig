const std = @import("std");

pub fn HashPool(comptime State: type, comptime Node: type) type {
    return struct {
        const Self: type = @This();
        const MemoryPool: type = std.heap.MemoryPool(Node);
        const Map: type = std.AutoHashMap(State, *Node);

        allocator: std.mem.Allocator,
        pool: MemoryPool,
        map: Map,

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            var map = Map.init(allocator);
            const size: u32 = @intCast(width * height);

            try map.ensureTotalCapacity(size);
            const pool = try MemoryPool.initPreheated(allocator, size);

            return .{
                .allocator = allocator,
                .pool = pool,
                .map = map,
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
            self.pool.deinit();
        }

        pub inline fn generate(self: *Self, state: State) !*Node {
            const result = try self.map.getOrPut(state);

            if (!result.found_existing) {
                const node: *Node = try self.pool.create();
                node.* = .{ .state = state };
                result.value_ptr.* = node;
            }

            return result.value_ptr.*;
        }

        pub fn reset(self: *Self) void {
            self.map.clearRetainingCapacity();
            _ = self.pool.reset(MemoryPool.ResetMode.retain_capacity);
        }
    };
}
