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
pub const state = @import("state/mod.zig");

const Node = node.Node(state.State);
const Domain = domain.BitGrid();
const NodeMap = node_pool.GridPool(state.State, Node);
const Open = open.PriorityQueue(*Node, node.lessThanFn);
const Heuristic = heuristic.Manhattan(state.State);
const Expander = expander.GridExpander4Connected(Domain, Node, NodeMap);
const Logger = logger.NoopLogger(Node);
const Search = search.UnidirectionalSearch(state.State, Node, Expander, Open, Heuristic, Logger);

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
        state.State{ .x = 0, .y = 0 },
        state.State{ .x = size - 1, .y = size - 1 },
    );
    const metrics = &_search.metrics;
    std.debug.print("{}\n", .{metrics});
}
