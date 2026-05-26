const std = @import("std");
const GridMapper = @import("./grid_mapper.zig").GridMapper;

pub fn BinnedGridMapper(comptime State: type, comptime Node: type) type {
    return struct {
        const Self = @This();
        const num_bins: usize = 36;
        const GridMapperType = GridMapper(State, Node);

        width: usize,
        height: usize,
        allocator: std.mem.Allocator,
        mappers: []GridMapperType,

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            const mappers = try allocator.alloc(GridMapperType, num_bins);
            for (mappers) |*mapper| {
                mapper.* = try GridMapperType.init(width, height, allocator);
            }

            return .{
                .width = width,
                .height = height,
                .allocator = allocator,
                .mappers = mappers,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.mappers) |*mapper| {
                mapper.deinit();
            }
            self.allocator.free(self.mappers);
        }

        pub fn reset(self: *Self) void {
            for (self.mappers) |*mapper| {
                mapper.reset();
            }
        }

        inline fn getBin(_: *Self, state: State) usize {
            const theta: f64 = state.get_theta();
            const bin = @floor((theta / comptime std.math.degreesToRadians(10)) + num_bins / 2);
            return @intFromFloat(bin);
        }

        pub fn get(self: *Self, state: State) !*?*Node {
            const bin = self.getBin(state);
            return self.mappers[bin].get(state);
        }
    };
}
