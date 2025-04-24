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

fn lessThanFn(a: *Node, b: *Node) bool {
    if (a.get_f() < b.get_f()) return true;
    if (a.get_f() > b.get_f()) return false;
    return a.get_g() > b.get_g();
}
const Domain = tigerhog.domain.BitGrid();
const NodeMap = tigerhog.node_mapper.StateNodeMap(State, Node);
const Open = tigerhog.open.PriorityQueue(*Node, lessThanFn);
const Heuristic = tigerhog.heuristic.Manhattan(State);
const Expander = tigerhog.expander.GridExpander4Connected(State, Domain, NodeMap);
const Search = tigerhog.search.UnidirectionalSearch(State, Node, NodeMap, Expander, Open, Heuristic);

pub fn main() !void {
    var dba = std.heap.DebugAllocator(.{ .safety = true }){};
    const allocator = dba.allocator();

    try run_astar(allocator);
}

pub fn run_astar(allocator: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();
    const maps = try cwd.openDir("src/maps/", .{ .iterate = true });
    var it = maps.iterate();

    var node_map = try NodeMap.init(allocator);
    defer node_map.deinit();

    var open = try Open.init(allocator, 2);
    defer open.deinit();

    var heuristic = Heuristic{};

    while (try it.next()) |entry| {
        if (std.mem.eql(u8, entry.name[(entry.name.len - 5)..], ".scen")) {
            const scen_file = try maps.openFile(entry.name, .{ .mode = .read_only });
            defer scen_file.close();

            const scenario = try tigerhog.scenario.load_gppc_scenarios(scen_file.reader(), allocator);
            defer allocator.free(scenario.instances);

            const map_file = try maps.openFile(scenario.map_name, .{ .mode = .read_only });
            defer map_file.close();

            var domain = try Domain.load_map(allocator, map_file.reader());
            defer domain.deinit();

            var expander = Expander.init(&domain, &node_map);
            var search = Search.init(&node_map, &expander, &open, &heuristic);

            for (scenario.instances) |instance| {
                // std.debug.print("{}\n", .{instance});
                _ = try search.query(State{ .x = instance.start_x, .y = instance.start_y }, State{ .x = instance.goal_x, .y = instance.goal_y });
                // const metrics = &search.metrics;
                // std.debug.print("{}\n", .{metrics.*});
            }
        }
    }
}
