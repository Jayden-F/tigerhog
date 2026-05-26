const std = @import("std");

pub fn NodePool(comptime Mapper: type, comptime Node: type, comptime State: type, comptime Allocator: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        mapper: Mapper,

        pub fn init(allocator: Allocator, mapper: Mapper) Self {
            return .{
                .allocator = allocator,
                .mapper = mapper,
            };
        }

        pub fn deinit(self: *Self) void {
            self.mapper.deinit();
        }

        pub fn reset(self: *Self) void {
            self.mapper.reset();
            _ = self.allocator.reset(.retain_capacity);
        }

        pub fn getOrCreate(self: *Self, state: State) !*Node {
            const slot: *?*Node = try self.mapper.get(state);
            if (slot.*) |node| return node;

            const node = try self.allocator.create();
            node.* = .{ .state = state };
            slot.* = node;
            return node;
        }
    };
}
