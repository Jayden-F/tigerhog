const std = @import("std");
const tigerhog = @import("libtigerhog");

pub fn compute_perfect_heuristic(allocator: std.mem.Allocator, domain: *tigerhog.domain.BitGrid(), target: tigerhog.state.State) !tigerhog.heuristic.Perfect.LookupHeuristic(tigerhog.state.SE2) {
    const State = tigerhog.state.State;

    const Node = tigerhog.node.Node(State);
    const NodePool = tigerhog.node_pool.GridPool(State, Node);
    const Expander = tigerhog.expander.CanonicalGridExpander(tigerhog.domain.BitGrid(), Node, NodePool);
    const Open = tigerhog.open.PriorityQueue(*Node, Node.lessThanFn);
    const Heuristic = tigerhog.heuristic.Zero(State);
    const Logger = tigerhog.heuristic.Perfect.CostLoggerT(Node);

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

    try std.io.getStdOut().writer().print("Computing Heuristic\n", .{});
    _ = try perfect.query(target, null);

    const metric = perfect.get_metrics();

    try std.io.getStdOut().writer().print("Complete {}\n", .{metric.*});

    const result = tigerhog.heuristic.Perfect.LookupHeuristic(tigerhog.state.SE2).init(domain.width, domain.height, logger.get_table(), allocator);
    return result;
}

pub fn main() !void {
    // var dba = std.heap.DebugAllocator(.{ .safety = true, .verbose_log = true }){};
    // const allocator = dba.allocator();

    const allocator = std.heap.smp_allocator;
    try run_astar(allocator);

    // std.debug.assert(!dba.detectLeaks());
}

pub fn run_astar(allocator: std.mem.Allocator) !void {
    const Domain = tigerhog.domain.BitGrid();
    const State = tigerhog.state.SE2;
    const Node = tigerhog.node.Node(State);
    const NodePool = tigerhog.node_pool.BinnedGridPool(State, Node);
    const Open = tigerhog.open.PriorityQueue(*Node, Node.lessThanFn);
    const Expander = tigerhog.expander.HybridExpander(Domain, Node, NodePool);
    const Heuristic = tigerhog.heuristic.Max(State);
    const Logger = tigerhog.logger.NoopLogger(Node);

    const Search = tigerhog.search.UnidirectionalSearch(
        State,
        Node,
        Expander,
        Open,
        Heuristic,
        Logger,
    );

    const stdout = std.io.getStdOut().writer();
    const cwd = std.fs.cwd();
    const maps = try cwd.openDir("src/maps/", .{ .iterate = true });
    var it = maps.iterate();

    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {
            try stdout.print("{s}\n", .{entry.name});
            // reading problem
            const scen_file = try maps.openFile(entry.name, .{ .mode = .read_only });
            var buffered_scen_file = std.io.bufferedReader(scen_file.reader());
            var scenario = try tigerhog.scenario.load_gppc_scenarios(buffered_scen_file.reader(), allocator);
            defer scenario.deinit();
            scen_file.close();

            const map_file = try maps.openFile(scenario.map_name, .{ .mode = .read_only });
            var buffered_map_file = std.io.bufferedReader(map_file.reader());

            // initialise search components
            var domain = try Domain.load_map(allocator, buffered_map_file.reader());
            defer domain.deinit();
            map_file.close();

            var node_pool = try NodePool.init(domain.width, domain.height, allocator);
            defer node_pool.deinit();
            var expander = Expander.init(&domain, &node_pool);
            defer expander.deinit();
            var open = try Open.init(allocator, 32 * domain.width * domain.height);
            defer open.deinit();
            var heuristic_dubins = tigerhog.heuristic.Dubins(State).init(5);

            var logger = Logger.init();
            defer logger.deinit();

            for (scenario.instances[1998..]) |instance| {
                var heuristic_perfect = try compute_perfect_heuristic(
                    allocator,
                    &domain,
                    .{
                        .x = instance.goal_x,
                        .y = instance.goal_y,
                    },
                );

                var heuristic = Heuristic.init(allocator);
                try heuristic.add(&heuristic_dubins);
                try heuristic.add(&heuristic_perfect);

                // assemble search algorithm
                var search = Search.init(
                    &expander,
                    &open,
                    &heuristic,
                    &logger,
                );

                // searching
                const target = try search.query(
                    State{
                        .x = @floatFromInt(instance.start_x),
                        .y = @floatFromInt(instance.start_y),
                        .theta = 0,
                    },
                    State{
                        .x = @floatFromInt(instance.goal_x),
                        .y = @floatFromInt(instance.goal_y),
                        .theta = 0,
                    },
                );

                const metrics = search.get_metrics();

                try stdout.print(
                    "{},\n",
                    .{std.json.fmt(
                        metrics.*,
                        .{},
                    )},
                );

                if (target) |reached| {
                    const path = try search.solution(reached, allocator);
                    const path_logger = tigerhog.logger.PathLogger(State).init(allocator, stdout.any());
                    try path_logger.log_path(path);
                }

                search.reset();
                return;
            }
        }
    }
}
