const std = @import("std");
const GridMapper = @import("./grid_mapper.zig").GridMapper;

pub fn BinnedGridMapper(comptime Node: type, comptime num_bins: usize) type {
    return struct {
        const Self = @This();
        const GridMapperType = GridMapper(Node);

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

        inline fn getBin(_: *Self, state: Node.State_T) usize {
            const theta: f64 = state.get_theta();
            const bin_size = comptime (2.0 * std.math.pi) / @as(f64, @floatFromInt(num_bins));
            const bin = @floor((theta / bin_size) + @as(f64, @floatFromInt(num_bins)) / 2.0);
            return @intFromFloat(bin);
        }

        pub fn get(self: *Self, state: Node.State_T) !*?*Node {
            const bin = self.getBin(state);
            return self.mappers[bin].get(state);
        }
    };
}
