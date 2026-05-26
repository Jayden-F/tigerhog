const std = @import("std");
const Cost = @import("cost.zig").Cost;

const Instance = struct {
    start_x: i32,
    start_y: i32,
    goal_x: i32,
    goal_y: i32,
    lb: Cost,
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

pub fn load_gppc_scenarios(reader: *std.Io.Reader, allocator: std.mem.Allocator) !Scenario {
    var map_name: []const u8 = undefined;

    _ = try reader.takeDelimiter('\n');

    var instances = std.array_list.Managed(Instance).init(allocator);

    while (try reader.takeDelimiter('\n')) |line| {
        var tokens = std.mem.tokenizeAny(u8, line, " \t");

        _ = tokens.next().?;

        map_name = tokens.next().?;

        _ = tokens.next().?;
        _ = tokens.next().?;

        const instance = Instance{
            .start_x = try std.fmt.parseInt(i32, tokens.next().?, 10),
            .start_y = try std.fmt.parseInt(i32, tokens.next().?, 10),
            .goal_x = try std.fmt.parseInt(i32, tokens.next().?, 10),
            .goal_y = try std.fmt.parseInt(i32, tokens.next().?, 10),
            .lb = try std.fmt.parseFloat(Cost, tokens.next().?),
        };
        try instances.append(instance);
    }

    return Scenario{
        .instances = try instances.toOwnedSlice(),
        .map_name = try allocator.dupe(u8, map_name),
        .allocator = allocator,
    };
}
