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
const Expander = tigerhog.expander.GridExpander8Connected(State, Domain);
const Search = tigerhog.search.UnidirectionalSearch(
    State,
    Node,
    NodePool,
    Expander,
    Open,
    Heuristic,
    Logger,
);
const Logger = tigerhog.logger.NoopLogger(Node);

pub fn main() !void {
    var dba = std.heap.DebugAllocator(.{ .safety = false }){};
    const allocator = dba.allocator();

    try run_astar(allocator);
}

pub fn run_astar(allocator: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();
    const maps = try cwd.openDir("src/maps/", .{ .iterate = true });
    var it = maps.iterate();

    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {

            // reading problem
            const scen_file = try maps.openFile(entry.name, .{ .mode = .read_only });
            defer scen_file.close();
            var scenario = try tigerhog.scenario.load_gppc_scenarios(scen_file.reader(), allocator);
            defer scenario.deinit();
            const map_file = try maps.openFile(scenario.map_name, .{ .mode = .read_only });
            defer map_file.close();

            // setting up algorithm
            var domain = try Domain.load_map(allocator, map_file.reader());
            defer domain.deinit();
            var node_pool = try NodePool.init(domain.width, domain.height, allocator);
            defer node_pool.deinit();
            var expander = Expander.init(&domain);
            defer expander.deinit();
            var open = try Open.init(allocator, domain.width * domain.height);
            defer open.deinit();
            var heuristic = Heuristic.init();
            defer heuristic.deinit();
            var logger = Logger.init();
            defer logger.deinit();

            // searching
            var search = Search.init(
                &node_pool,
                &expander,
                &open,
                &heuristic,
                &logger,
            );
            defer search.deinit();

            for (scenario.instances) |instance| {
                _ = try search.query(
                    State{ .x = instance.start_x, .y = instance.start_y },
                    State{ .x = instance.goal_x, .y = instance.goal_y },
                );

                const metrics = &search.metrics;
                try std.io.getStdOut().writer().print("{},\n", .{std.json.fmt(metrics.*, .{})});
            }
        }
    }
}
