const std = @import("std");
pub fn GridPool(comptime State: type, comptime Node: type) type {
    return struct {
        const SearchNode = struct {
            // Used to determine if the memory associated with this search node is valid.
            // search nodes that do not much have been freed or are null.
            search_number: usize,
            node: ?*Node,
        };

        const Self: type = @This();
        const NodePool: type = std.heap.MemoryPool(Node);
        const NodeMap: type = []SearchNode;

        width: usize,
        height: usize,
        allocator: std.mem.Allocator,
        pool: NodePool,
        map: NodeMap,
        // search_number is initialised to 1, so that the default initialised map is invalidated.
        search_number: usize = 1,

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            var map = try allocator.alloc(SearchNode, width * height);
            @memset(map[0..], SearchNode{ .search_number = 0, .node = null });

            const pool = try NodePool.initPreheated(allocator, width * height);
            // const pool = NodePool.init(allocator);

            return .{
                .width = width,
                .height = height,
                .allocator = allocator,
                .pool = pool,
                .map = map,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.map);
            self.pool.deinit();
        }

        inline fn get_index(self: *const Self, state: State) usize {
            const x: usize = switch (@typeInfo(@TypeOf(state.get_x()))) {
                .float => @intFromFloat(state.get_x()),
                .int => @intCast(state.get_x()),
                else => @compileError("Unsupported type for get_x()"),
            };

            const y: usize = switch (@typeInfo(@TypeOf(state.get_y()))) {
                .float => @intFromFloat(state.get_y()),
                .int => @intCast(state.get_y()),
                else => @compileError("Unsupported type for get_y()"),
            };

            return y * self.width + x;
        }

        pub inline fn generate(self: *Self, state: State) !*Node {
            @setRuntimeSafety(false);
            const index = self.get_index(state);
            const search_node = &self.map[index];

            if (search_node.search_number != self.search_number) {
                const node: *Node = try self.pool.create();
                node.* = .{ .state = state };
                search_node.* = .{ .node = node, .search_number = self.search_number };
            }

            return search_node.node.?;
        }

        pub fn reset(self: *Self) void {
            self.search_number += 1;
            _ = self.pool.reset(NodePool.ResetMode.retain_capacity);
        }
    };
}
