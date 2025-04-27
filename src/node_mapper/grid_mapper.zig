const std = @import("std");

pub fn StateNodeMap(comptime State: type, comptime Node: type) type {
    return struct {
        const SearchNode = struct {
            search_number: usize = 0,
            node: ?*Node,
        };

        const Self: type = @This();
        const MemoryPool: type = std.heap.MemoryPool(Node);
        const Map: type = []SearchNode;

        width: usize,
        height: usize,
        allocator: std.mem.Allocator,
        pool: MemoryPool,
        map: Map,
        search_number: usize = 0,

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            var map = try allocator.alloc(SearchNode, width * height);
            @memset(map[0..], SearchNode{ .search_number = 0, .node = null });

            const pool = try MemoryPool.initPreheated(allocator, width * height);

            return .{
                .width = width,
                .height = height,
                .allocator = allocator,
                .pool = pool,
                .map = map,
                .search_number = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.map);
            self.pool.deinit();
        }

        inline fn get_index(self: *const Self, x: i32, y: i32) usize {
            @setRuntimeSafety(false);
            const _x: usize = @intCast(x);
            const _y: usize = @intCast(y);
            return self.width * _y + _x;
        }

        pub inline fn generate(self: *Self, state: State) *Node {
            @setRuntimeSafety(false);
            const index = self.get_index(state.get_x(), state.get_y());

            const search_node = &self.map[index];

            if (search_node.search_number != self.search_number) {
                const node: *Node = try self.pool.create();
                node.* = Node.default(state);
                search_node.node = node;
                search_node.search_number = self.search_number;
            }

            std.debug.assert(std.meta.eql(search_node.node.?.get_state(), state));
            return search_node.node.?;
        }

        pub fn reset(self: *Self) void {
            self.search_number += 1;
            _ = self.pool.reset(MemoryPool.ResetMode.retain_capacity);
        }
    };
}
