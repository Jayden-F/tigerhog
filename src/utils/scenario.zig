const std = @import("std");

const Instance = struct {
    start_x: f64,
    start_y: f64,
    goal_x: f64,
    goal_y: f64,
    lb: f64,
};

const Scenario = struct {
    map_name: []const u8,
    instances: []Instance,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.map_name);
        self.allocator.free(self.instances);
    }
};

pub fn load_gppc_scenarios(stream: anytype, allocator: std.mem.Allocator) !Scenario {
    var buf: [256]u8 = undefined;
    var map_name: []const u8 = undefined;

    // remove header
    _ = try stream.readUntilDelimiter(&buf, '\n');

    var instances = std.ArrayList(Instance).init(allocator);

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var tokens = std.mem.tokenizeAny(u8, line, " \t");

        _ = tokens.next().?;

        map_name = tokens.next().?;

        _ = tokens.next().?;
        _ = tokens.next().?;

        const instance = Instance{
            .start_x = try std.fmt.parseFloat(f64, tokens.next().?),
            .start_y = try std.fmt.parseFloat(f64, tokens.next().?),
            .goal_x = try std.fmt.parseFloat(f64, tokens.next().?),
            .goal_y = try std.fmt.parseFloat(f64, tokens.next().?),
            .lb = try std.fmt.parseFloat(f64, tokens.next().?),
        };
        try instances.append(instance);
    }
    return Scenario{
        .instances = try instances.toOwnedSlice(),
        .map_name = try allocator.dupe(u8, map_name),
        .allocator = allocator,
    };
}
