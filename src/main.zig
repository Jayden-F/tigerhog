const std = @import("std");

const tigerhog = @import("tigerhog_lib");

const State = packed struct {
    const Self = @This();
    x: i32,
    y: i32,

    pub inline fn get_x(self: *const Self) i32 {
        return self.x;
    }

    pub inline fn get_y(self: *const Self) i32 {
        return self.y;
    }

    pub inline fn to_string(self: *const Self, allocator: std.mem.Allocator) ![]u8 {
        return try std.fmt.allocPrint(
            allocator,
            "x: {d}, y: {d},",
            .{ self.get_x(), self.get_y() },
        );
    }
};

const Node = tigerhog.node.Node(State);

fn lessThanFn(a: *const Node, b: *const Node) bool {
    if (a.get_f() < b.get_f()) return true;
    if (a.get_f() > b.get_f()) return false;
    return a.get_g() > b.get_g();
}

const Domain = tigerhog.domain.BitGrid();
const NodePool = tigerhog.node_pool.GridPool(State, Node);
const Open = tigerhog.open.PriorityQueue(*Node, lessThanFn);
const Heuristic = tigerhog.heuristic.Octile(State);
const Expander = tigerhog.expander.CanonicalGridExpander(Domain, Node, NodePool);
const Logger = tigerhog.logger.Logger(Node);

const Search = tigerhog.search.UnidirectionalSearch(
    State,
    Node,
    Expander,
    Open,
    Heuristic,
    Logger,
);

pub fn main() !void {

    // var dba = std.heap.DebugAllocator(.{ .safety = false }){};
    // var allocator = dba.allocator();

    const allocator = std.heap.smp_allocator;

    const writer = std.io.getStdOut().writer();
    var logger = Logger.init(allocator, writer.any());
    defer logger.deinit();

    try run_astar(allocator, &logger);
}

pub fn run_astar(allocator: std.mem.Allocator, logger: *Logger) !void {
    const cwd = std.fs.cwd();
    const maps = try cwd.openDir("src/maps/", .{ .iterate = true });
    var it = maps.iterate();

    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {

            // reading problem
            const scen_file = try maps.openFile(entry.name, .{ .mode = .read_only });
            defer scen_file.close();
            var buffered_scen_file = std.io.bufferedReader(scen_file.reader());
            var scenario = try tigerhog.scenario.load_gppc_scenarios(buffered_scen_file.reader(), allocator);
            defer scenario.deinit();

            const map_file = try maps.openFile(scenario.map_name, .{ .mode = .read_only });
            var buffered_map_file = std.io.bufferedReader(map_file.reader());
            defer map_file.close();

            // initialise search components
            var domain = try Domain.load_map(allocator, buffered_map_file.reader());
            defer domain.deinit();
            var node_pool = try NodePool.init(domain.width, domain.height, allocator);
            defer node_pool.deinit();
            var expander = Expander.init(&domain, &node_pool);
            defer expander.deinit();
            var open = try Open.init(allocator, domain.width * domain.height);
            defer open.deinit();
            var heuristic = Heuristic.init();
            defer heuristic.deinit();

            // assemble search algorithm
            var search = Search.init(
                &expander,
                &open,
                &heuristic,
                logger,
            );

            for (scenario.instances) |instance| {
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

                const metrics = &search.metrics;

                // try std.io.getStdOut().writer().print("{},\n", .{std.json.fmt(instance, .{})});
                try std.io.getStdOut().writer().print("{},\n", .{std.json.fmt(metrics.*, .{})});
                std.debug.assert(@abs(instance.lb - metrics.solution_cost) < 1e-6);
                search.reset();
            }
        }
    }
}
