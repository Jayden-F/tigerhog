const std = @import("std");

pub const node = @import("node/node.zig");
pub const open = @import("open/pqueue.zig");
pub const domain = @import("domain/bit_grid.zig");
pub const node_mapper = @import("node_mapper/node_mapper.zig");
pub const heuristic = @import("heuristic/manhattan.zig");
pub const search = @import("search/unidirectional_search.zig");
pub const expander = @import("expander/grid_expander.zig");
pub const scenario = @import("utils/scenario.zig");

const State = struct {
    const Self = @This();
    x: u32,
    y: u32,

    pub fn get_x(self: *const Self) u32 {
        return self.x;
    }

    pub fn get_y(self: *const Self) u32 {
        return self.y;
    }
};

const Node = node.Node(State);

fn lessThanFn(a: *Node, b: *Node) bool {
    if (a.get_f() < b.get_f()) return true;
    if (a.get_f() > b.get_f()) return false;
    return a.get_g() > b.get_g();
}

const Domain = domain.BitGrid();
const NodeMap = node_mapper.StateNodeMap(State, Node);
const Open = open.PriorityQueue(*Node, lessThanFn);
const Heuristic = heuristic.Manhattan(State);
const Expander = expander.GridExpander4Connected(State, Domain, NodeMap);
const Search = search.UnidirectionalSearch(State, Node, NodeMap, Domain, Expander, Open, Heuristic);

test "run astar" {
    const allocator = std.testing.allocator;
    const size = 10_000;
    var _domain = try Domain.init(allocator, size, size);

    for (0..size) |x| {
        for (0..size) |y| {
            _domain.set(@intCast(x), @intCast(y), true);
        }
    }

    defer _domain.deinit();
    var _map = try NodeMap.init(allocator);
    defer _map.deinit();
    var _open = try Open.init(allocator, 1);
    defer _open.deinit();
    var _heuristic = Heuristic{};
    var _expander = Expander.init(&_domain, &_map);
    var _search = Search.init(&_domain, &_map, &_expander, &_open, &_heuristic, allocator);

    std.debug.print("Searching\n", .{});

    const start_time = std.time.milliTimestamp();
    const result = try _search.query(State{ .x = 0, .y = 0 }, State{ .x = size - 1, .y = size - 1 });
    const duration = std.time.milliTimestamp() - start_time;
    std.debug.print("Duration   (ms): {}\n", .{duration});

    std.debug.print("Solution\n", .{});
    if (result) |solution| {
        defer allocator.free(solution);
        // for (solution) |state| {
        //     std.debug.print("{}\n", .{state});
        // }
    }
}
