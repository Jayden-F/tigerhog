const std = @import("std");

pub fn StateNodeMap(comptime State: type, comptime Node: type) type {
    return struct {
        const Self: type = @This();
        const MemoryPool: type = std.heap.MemoryPool(Node);
        const Map: type = std.AutoHashMap(State, *Node);

        allocator: std.mem.Allocator,
        pool: MemoryPool,
        map: Map,

        pub fn init(allocator: std.mem.Allocator) !Self {
            const map = Map.init(allocator);
            const pool = MemoryPool.init(allocator);
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
                node.* = Node.default(state);
                result.value_ptr.* = node;
            }

            std.debug.assert(std.meta.eql(result.value_ptr.*.get_state(), state));

            return result.value_ptr.*;
        }

        pub fn reset(self: *Self) void {
            self.map.clearRetainingCapacity();
            _ = self.pool.reset(MemoryPool.ResetMode.retain_capacity);
        }
    };
}
