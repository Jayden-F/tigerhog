const std = @import("std");

pub fn NodePool(comptime Node: type, comptime Mapper: type, comptime MemoryPool: type) type {
    return struct {
        const Self = @This();

        mapper: Mapper,
        memory_pool: MemoryPool,

        pub fn init(memory_pool: MemoryPool, mapper: Mapper) Self {
            return .{
                .memory_pool = memory_pool,
                .mapper = mapper,
            };
        }

        pub fn deinit(self: *Self) void {
            self.memory_pool.deinit();
            self.mapper.deinit();
        }

        pub fn reset(self: *Self) void {
            self.mapper.reset();
            _ = self.memory_pool.reset(.retain_capacity);
        }

        pub fn getOrCreate(self: *Self, state: Node.State_T) !*Node {
            const slot: *?*Node = try self.mapper.get(state);
            if (slot.*) |node| return node;

            const node = try self.memory_pool.create();
            node.* = .{ .state = state };
            slot.* = node;
            return node;
        }
    };
}
