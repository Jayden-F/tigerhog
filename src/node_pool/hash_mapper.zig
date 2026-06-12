const std = @import("std");

pub fn HashMapper(comptime Node: type) type {
    return struct {
        const Self = @This();
        const Map = std.AutoHashMap(Node.State_T, ?*Node);

        allocator: std.mem.Allocator,
        map: Map,

        pub fn init(allocator: std.mem.Allocator, size: u32) !Self {
            var map = Map.init(allocator);
            try map.ensureTotalCapacity(size);
            return .{
                .allocator = allocator,
                .map = map,
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn reset(self: *Self) void {
            self.map.clearRetainingCapacity();
        }

        pub inline fn get(self: *Self, state: Node.State_T) !*?*Node {
            const result = try self.map.getOrPut(state);
            if (!result.found_existing) {
                result.value_ptr.* = null;
            }
            return result.value_ptr;
        }
    };
}
