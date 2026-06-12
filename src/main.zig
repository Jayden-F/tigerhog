const std = @import("std");
const tigerhog = @import("libtigerhog");

const State = tigerhog.state.State;
const Node = tigerhog.node.Node(State);

const Mapper = tigerhog.node_pool.GridMapper(Node);
const NodePool = tigerhog.node_pool.GridNodePool(Node);
const Expander = tigerhog.expander.JpsExpander(Domain, Node, NodePool);

const Open = tigerhog.open.PriorityQueue(*Node, Node.lessThanFn);
const Domain = tigerhog.domain.BitGrid();
const Heuristic = tigerhog.heuristic.Octile(State);
const Logger = tigerhog.logger.Logger(Node);

const Search = tigerhog.search.UnidirectionalSearch(
    State,
    Node,
    Expander,
    Open,
    Heuristic,
    Logger,
);

pub fn run_astar(io: std.Io, allocator: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();

    var log_buffer: [2048]u8 = undefined;

    // var log_file = try std.Io.Dir.createFile(cwd, io, "log.txt", .{});
    // var log_writer = std.Io.File.writer(log_file, io, &log_buffer);

    var log_writer = std.Io.File.writer(std.Io.File.stdout(), io, &log_buffer);
    const log = &log_writer.interface;

    const maps = try std.Io.Dir.openDir(cwd, io, "src/maps/", .{ .iterate = true });
    var dir_reader_buffer: [1024]u8 align(@alignOf(usize)) = undefined;
    var it = std.Io.Dir.Reader.init(maps, &dir_reader_buffer);

    while (try std.Io.Dir.Reader.next(&it, io)) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {
            try log.print("{s}\n", .{entry.name});
            // reading problem
            const scen_file = try std.Io.Dir.openFile(maps, io, entry.name, .{ .mode = .read_only });
            var reader_buffer: [1024]u8 = undefined;
            var file_reader = std.Io.File.reader(scen_file, io, &reader_buffer);
            var scenario = try tigerhog.scenario.load_gppc_scenarios(&file_reader.interface, allocator);
            defer scenario.deinit();
            std.Io.File.close(scen_file, io);

            const map_file = try std.Io.Dir.openFile(maps, io, scenario.map_name, .{ .mode = .read_only });
            // initialise search components
            var map_reader_buffer: [5120]u8 = undefined;
            var map_file_reader = std.Io.File.reader(map_file, io, &map_reader_buffer);
            var domain = try Domain.load_map(&map_file_reader.interface, allocator);
            defer domain.deinit();
            std.Io.File.close(map_file, io);

            var mapper = try Mapper.init(domain.width, domain.height, allocator);
            errdefer mapper.deinit();
            var memory_pool = try std.heap.memory_pool.Managed(Node).initCapacity(allocator, domain.width * domain.height);
            errdefer memory_pool.deinit();
            var node_pool = NodePool.init(memory_pool, mapper);
            defer node_pool.deinit();

            var open = try Open.init(allocator, domain.width * domain.height);
            defer open.deinit();
            var heuristic = Heuristic.init();
            defer heuristic.deinit();

            // var expander = Expander.init(&domain, &node_pool);
            // defer expander.deinit();

            var search_trace = try cwd.createFile(io, "search.trace.yaml", .{});
            defer search_trace.close(io);

            var search_trace_buffer: [1024]u8 = undefined;
            var search_trace_writer = search_trace.writer(io, &search_trace_buffer);
            var logger = Logger.init(&search_trace_writer.interface);

            // var logger = Logger.init();
            defer logger.deinit();

            for (0.., scenario.instances) |i, instance| {
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
                    io,
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
                try log.print("{s}:{}{f},\n", .{ scenario.map_name[0 .. scenario.map_name.len - 4], i, metrics });

                // if (target) |reached| {
                //     const path = try search.solution(reached, allocator);
                //     const path_logger = tigerhog.logger.PathLogger(State).init(allocator, stdout.any());
                //     try path_logger.log_path(path);
                // }

                // std.debug.assert(std.math.approxEqAbs(f64, metrics.solution_cost, instance.lb, 1e-6));

                search.reset();
                try logger.flush();
            }
        }
    }
    try log.flush();
}

pub fn main() !void {
    // var dba = std.heap.DebugAllocator(.{ .safety = true, .verbose_log = true }){};
    // const allocator = dba.allocator();

    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

    const allocator = std.heap.smp_allocator;
    try run_astar(io, allocator);

    // std.debug.assert(!dba.detectLeaks());
}
