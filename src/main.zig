const std = @import("std");
const tigerhog = @import("libtigerhog");

const State = tigerhog.state.State;
const Node = tigerhog.node.Node(State);
const NodePool = tigerhog.node_pool.GridPool(State, Node);
const Open = tigerhog.open.PriorityQueue(*Node, Node.lessThanFn);
const Domain = tigerhog.domain.BitGrid();
const Expander = tigerhog.expander.JpsExpander(Domain, Node, NodePool);
const Heuristic = tigerhog.heuristic.Octile(State);
const Logger = tigerhog.logger.NoopLogger(Node);

const Search = tigerhog.search.UnidirectionalSearch(
    State,
    Node,
    Expander,
    Open,
    Heuristic,
    Logger,
);

pub fn run_astar(allocator: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();

    var log_buffer: [2048]u8 = undefined;

    // var log_file = try cwd.createFile("log.txt", .{});
    // var log_writer = log_file.writer(&log_buffer);

    var log_writer = std.fs.File.stdout().writer(&log_buffer);
    const log = &log_writer.interface;

    const maps = try cwd.openDir("src/maps/", .{ .iterate = true });
    var it = maps.iterate();

    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {
            try log.print("{s}\n", .{entry.name});
            // reading problem
            const scen_file = try maps.openFile(entry.name, .{ .mode = .read_only });
            var reader_buffer: [1024]u8 = undefined;
            var file_reader = scen_file.reader(&reader_buffer);
            var scenario = try tigerhog.scenario.load_gppc_scenarios(&file_reader.interface, allocator);
            defer scenario.deinit();
            scen_file.close();

            const map_file = try maps.openFile(scenario.map_name, .{ .mode = .read_only });
            // initialise search components
            var map_reader_buffer: [5120]u8 = undefined;
            var map_file_reader = map_file.reader(&map_reader_buffer);
            var domain = try Domain.load_map(&map_file_reader.interface, allocator);
            defer domain.deinit();
            map_file.close();

            var node_pool = try NodePool.init(domain.width, domain.height, allocator);
            defer node_pool.deinit();
            var open = try Open.init(allocator, domain.width * domain.height);
            defer open.deinit();
            var heuristic = Heuristic.init();
            defer heuristic.deinit();

            // var search_trace_buffer: [5120]u8 = undefined;
            // var search_trace = try cwd.createFile("search.trace.yaml", .{});
            // defer search_trace.close();
            // var search_trace_writer = search_trace.writer(&search_trace_buffer);
            // var logger = Logger.init(&search_trace_writer.interface);
            var logger = Logger.init();
            defer logger.deinit();
            // defer search_trace.close();

            for (scenario.instances) |instance| {
                var expander = Expander.init(
                    &domain,
                    &node_pool,
                    State{
                        .x = instance.goal_x,
                        .y = instance.goal_y,
                    },
                );
                defer expander.deinit();
                // assemble search algorithm
                var search = Search.init(
                    &expander,
                    &open,
                    &heuristic,
                    &logger,
                );

                // searching
                _ = try search.query(
                    State{
                        .x = instance.start_x,
                        .y = instance.start_y,
                    },
                    State{
                        .x = instance.goal_x,
                        .y = instance.goal_y,
                    },
                );

                const metrics = search.get_metrics();
                try log.print("{f},\n", .{metrics});

                // if (target) |reached| {
                //     const path = try search.solution(reached, allocator);
                //     const path_logger = tigerhog.logger.PathLogger(State).init(allocator, stdout.any());
                //     try path_logger.log_path(path);
                // }

                search.reset();
            }
        }
    }

    try log.flush();
}

pub fn main() !void {
    // var dba = std.heap.DebugAllocator(.{ .safety = true, .verbose_log = true }){};
    // const allocator = dba.allocator();

    const allocator = std.heap.smp_allocator;
    try run_astar(allocator);

    // std.debug.assert(!dba.detectLeaks());
}
