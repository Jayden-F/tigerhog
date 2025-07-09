const std = @import("std");

const tigerhog = @import("tigerhog_lib");

const State = struct {
    const Self = @This();
    x: f64,
    y: f64,
    theta: f64,

    pub inline fn get_x(self: *const Self) f64 {
        return self.x;
    }

    pub inline fn get_y(self: *const Self) f64 {
        return self.y;
    }

    pub inline fn get_theta(self: *const Self) f64 {
        return self.theta;
    }

    pub inline fn to_string(self: *const Self, allocator: std.mem.Allocator) ![]u8 {
        return try std.fmt.allocPrint(
            allocator,
            "x: {d}, y: {d}, theta: {d}",
            .{ self.get_x(), self.get_y(), self.get_theta() },
        );
    }

    pub inline fn to_hash(self: *const Self) u64 {
        return std.hash.Wyhash.hash(0, std.mem.asBytes(&self));
    }
};

const Node = tigerhog.node.Node(State);

fn lessThanFn(a: *const Node, b: *const Node) bool {
    if (a.get_f() < b.get_f()) return true;
    if (a.get_f() > b.get_f()) return false;
    return a.get_g() > b.get_g();
}

const Domain = tigerhog.domain.BitGrid();
const NodePool = tigerhog.node_pool.BinnedGridPool(State, Node);
const Open = tigerhog.open.PriorityQueue(*Node, lessThanFn);
const Heuristic = tigerhog.heuristic.Dubins(State);
const Expander = tigerhog.expander.HybridExpander(Domain, Node, NodePool);
const Logger = tigerhog.logger.NoopLogger(Node);

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
    try run_astar(allocator);
}

pub fn run_astar(allocator: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();
    const maps = try cwd.openDir("src/maps/", .{ .iterate = true });
    var it = maps.iterate();

    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {
            try std.io.getStdOut().writer().print("{s}\n", .{entry.name});
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
            var open = try Open.init(allocator, 72 * domain.width * domain.height);
            defer open.deinit();
            var heuristic = Heuristic.init(1.0 / @tan(std.math.degreesToRadians(10.0)));
            defer heuristic.deinit();

            var logger = Logger.init();
            defer logger.deinit();

            // assemble search algorithm
            var search = Search.init(
                &expander,
                &open,
                &heuristic,
                &logger,
            );

            for (scenario.instances[3100..]) |instance| {
                // searching
                const target = try search.query(
                    State{
                        .x = instance.start_x,
                        .y = instance.start_y,
                        .theta = 0.0,
                    },
                    State{
                        .x = instance.goal_x,
                        .y = instance.goal_y,
                        .theta = 0.0,
                    },
                );

                const metrics = search.get_metrics();

                const stdout = std.io.getStdOut().writer();
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

                // std.debug.assert(@abs(instance.lb - metrics.solution_cost) < 1e-6);
                search.reset();

                return;
            }
        }
    }
}
