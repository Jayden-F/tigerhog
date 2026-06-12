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

test "run astar" {
    const Node = node.Node(state.State);
    const Domain = domain.BitGrid();
    const Mapper = node_pool.GridMapper(Node);
    const NodePool = node_pool.GridNodePool(Node);
    const Open = open.PriorityQueue(*Node, Node.lessThanFn);
    const Heuristic = heuristic.Manhattan(state.State);
    const Expander = expander.GridExpander4Connected(Domain, Node, NodePool);
    const Logger = logger.NoopLogger(Node);
    const Search = search.UnidirectionalSearch(state.State, Node, Expander, Open, Heuristic, Logger);

    const allocator = std.testing.allocator;
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    const size = 10_000;
    var _domain = try Domain.init(allocator, size, size);

    for (0..size) |x| {
        for (0..size) |y| {
            _domain.set(@intCast(x), @intCast(y), true);
        }
    }

    defer _domain.deinit();

    var _mapper = try Mapper.init(_domain.width, _domain.height, allocator);
    errdefer _mapper.deinit();
    var _memory_pool = std.heap.memory_pool.Managed(Node).init(allocator);
    errdefer _memory_pool.deinit();
    var _node_pool = NodePool.init(_memory_pool, _mapper);
    defer _node_pool.deinit();

    var _open = try Open.init(allocator, 1);
    defer _open.deinit();

    var _heuristic = Heuristic{};
    var _expander = Expander.init(&_domain, &_node_pool);
    var _logger = Logger.init();

    var _search = Search.init(
        io,
        &_expander,
        &_open,
        &_heuristic,
        &_logger,
    );

    // std.debug.print("Searching\n", .{});
    _ = try _search.query(
        state.State{ .x = 0, .y = 0 },
        state.State{ .x = size - 1, .y = size - 1 },
    );
    // const metrics = &_search.metrics;
    // std.debug.print("{f}\n", .{metrics});
}
