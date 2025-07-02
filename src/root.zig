const std = @import("std");

pub const domain = @import("domain/bit_grid.zig");
pub const expander = @import("expander/mod.zig");
pub const heuristic = @import("heuristic/mod.zig");
pub const logger = @import("logger/mod.zig");
pub const node = @import("node/node.zig");
pub const node_pool = @import("node_pool/mod.zig");
pub const open = @import("open/pqueue.zig");
pub const search = @import("search/unidirectional_search.zig");
pub const scenario = @import("utils/scenario.zig");

const State = struct {
    const Self = @This();
    x: i32,
    y: i32,

    pub fn get_x(self: *const Self) i32 {
        return self.x;
    }

    pub fn get_y(self: *const Self) i32 {
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
const NodeMap = node_pool.GridPool(State, Node);
const Open = open.PriorityQueue(*Node, lessThanFn);
const Heuristic = heuristic.Manhattan(State);
const Expander = expander.GridExpander4Connected(Domain, Node, NodeMap);
const Logger = logger.NoopLogger(Node);
const Search = search.UnidirectionalSearch(State,  Node, Expander, Open, Heuristic, Logger);

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
    var _map = try NodeMap.init(_domain.width, _domain.height, allocator);
    defer _map.deinit();
    var _open = try Open.init(allocator, 1);
    defer _open.deinit();

    var _heuristic = Heuristic{};
    var _expander = Expander.init(&_domain, &_map);
    var _logger = Logger.init();

    var _search = Search.init(
        &_expander,
        &_open,
        &_heuristic,
        &_logger,
    );

    std.debug.print("Searching\n", .{});
    _ = try _search.query(
        State{ .x = 0, .y = 0 },
        State{ .x = size - 1, .y = size - 1 },
    );
    const metrics = &_search.metrics;
    std.debug.print("{}\n", .{metrics});
}
