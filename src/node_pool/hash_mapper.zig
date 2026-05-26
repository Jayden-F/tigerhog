const std = @import("std");

pub fn HashMapper(comptime State: type, comptime Node: type) type {
    return struct {
        const Self = @This();
        const Map = std.AutoHashMap(State, ?*Node);

        allocator: std.mem.Allocator,
        map: Map,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return .{
                .allocator = allocator,
                .map = Map.init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn reset(self: *Self) void {
            self.map.clearRetainingCapacity();
        }

        pub fn get(self: *Self, state: State) !*?*Node {
            const result = try self.map.getOrPut(state);
            if (!result.found_existing) {
                result.value_ptr.* = null;
            }
            return result.value_ptr;
        }
    };
}
