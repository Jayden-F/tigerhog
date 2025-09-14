const std = @import("std");
const tigerhog = @import("libtigerhog");

const State = tigerhog.state.State;
const Node = tigerhog.node.Node(State);
const NodePool = tigerhog.node_pool.GridPool(State, Node);
const Expander = tigerhog.expander.CanonicalGridExpander(tigerhog.domain.BitGrid(), Node, NodePool);
const Open = tigerhog.open.PriorityQueue(*Node, Node.lessThanFn);
const Heuristic = tigerhog.heuristic.Zero(State);
const Logger = tigerhog.heuristic.Perfect.CostLoggerT(Node);

pub fn compute_perfect_heuristic(allocator: std.mem.Allocator, domain: *tigerhog.domain.BitGrid(), target: tigerhog.state.State) !tigerhog.heuristic.Perfect.LookupHeuristic(tigerhog.state.SE2) {
    const Search = tigerhog.search.UnidirectionalSearch(
        State,
        Node,
        Expander,
        Open,
        Heuristic,
        Logger,
    );

    var node_pool = try NodePool.init(domain.width, domain.height, allocator);
    defer node_pool.deinit();
    var expander = Expander.init(domain, &node_pool);
    defer expander.deinit();
    var open = try Open.init(allocator, domain.width * domain.height);
    defer open.deinit();
    var heuristic = Heuristic.init();
    defer heuristic.deinit();
    var logger = try Logger.init(domain.width, domain.height, allocator);
    defer logger.deinit();

    var perfect = Search.init(&expander, &open, &heuristic, &logger);
    defer perfect.deinit();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("Computing Heuristic\n", .{});
    _ = try perfect.query(target, null);

    const metrics = perfect.get_metrics();

    try stdout.print(
        "{f},\n",
        .{std.json.fmt(
            metrics.*,
            .{},
        )},
    );

    const result = tigerhog.heuristic.Perfect.LookupHeuristic(tigerhog.state.SE2).init(domain.width, domain.height, logger.get_table(), allocator);
    return result;
}
