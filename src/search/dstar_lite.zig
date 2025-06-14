const std = @import("std");

pub fn DStarLite(
    comptime State: type,
    comptime Node: type,
    comptime SearchAlgo: type,
) type {
    return struct {
        const Self = @This();

        search_algo: SearchAlgo,

        pub fn init(search_algo: *SearchAlgo) Self {
            return .{ .search_algo = search_algo };
        }

        pub fn query(self: *Self, start_state: State, target_state: State) !?*const Node {
            return self.search_algo.query(start_state, target_state);
        }

        pub fn update(self: *Self, start_state: State, target_state: State) !?*const Node {
            return self.search_algo.query(start_state, target_state);
        }

        pub fn reset(self: *Self) void {
            self.search_algo.reset();
        }
    };
}
