const std = @import("std");
const direction = @import("../utils/direction.zig");

pub fn GridExpander8Connected(comptime State: type, comptime Domain: type) type {
    const Neighbours = std.EnumSet(direction.Direction);

    const Edge = struct {
        state: State,
        cost: f64,
    };

    return struct {
        const Self = @This();

        domain: *Domain,
        edges: [8]Edge = undefined,
        num_neighbours: usize = 0,

        pub fn init(domain: *Domain) Self {
            return .{
                .domain = domain,
            };
        }
        pub fn deinit(_: *Self) void {}

        pub inline fn get_neighbours(self: *const Self, x: i32, y: i32) Neighbours {
            var result = Neighbours.initEmpty();

            const north = self.domain.is_valid(x, y - 1);
            if (north) result.insert(.NORTH);
            const south = self.domain.is_valid(x, y + 1);
            if (south) result.insert(.SOUTH);

            if (self.domain.is_valid(x + 1, y)) {
                result.insert(.EAST);

                if (north and self.domain.is_valid(x + 1, y - 1)) {
                    result.insert(.NORTH_EAST);
                }
                if (south and self.domain.is_valid(x + 1, y + 1)) {
                    result.insert(.SOUTH_EAST);
                }
            }

            if (self.domain.is_valid(x - 1, y)) {
                result.insert(.WEST);

                if (north and self.domain.is_valid(x - 1, y - 1)) {
                    result.insert(.NORTH_WEST);
                }

                if (south and self.domain.is_valid(x - 1, y + 1)) {
                    result.insert(.SOUTH_WEST);
                }
            }
            return result;
        }

        pub fn expand(self: *Self, current: State) []const Edge {
            self.reset();

            const x: i32 = current.get_x();
            const y: i32 = current.get_y();

            std.debug.assert(self.domain.is_valid(x, y));

            const neighbours = self.get_neighbours(x, y);

            if (neighbours.contains(.NORTH)) {
                self.add_neighbour(.{ .x = x, .y = y - 1 }, 1.0);
            }
            if (neighbours.contains(.EAST)) {
                self.add_neighbour(.{ .x = x + 1, .y = y }, 1.0);
            }
            if (neighbours.contains(.SOUTH)) {
                self.add_neighbour(.{ .x = x, .y = y + 1 }, 1.0);
            }
            if (neighbours.contains(.WEST)) {
                self.add_neighbour(.{ .x = x - 1, .y = y }, 1.0);
            }
            if (neighbours.contains(.NORTH_EAST)) {
                self.add_neighbour(.{ .x = x + 1, .y = y - 1 }, std.math.sqrt2);
            }
            if (neighbours.contains(.SOUTH_EAST)) {
                self.add_neighbour(.{ .x = x + 1, .y = y + 1 }, std.math.sqrt2);
            }
            if (neighbours.contains(.SOUTH_WEST)) {
                self.add_neighbour(.{ .x = x - 1, .y = y + 1 }, std.math.sqrt2);
            }
            if (neighbours.contains(.NORTH_WEST)) {
                self.add_neighbour(.{ .x = x - 1, .y = y - 1 }, std.math.sqrt2);
            }
            return self.edges[0..self.num_neighbours];
        }

        inline fn add_neighbour(self: *Self, state: State, cost: f64) void {
            self.edges[self.num_neighbours] = .{ .state = state, .cost = cost };
            self.num_neighbours += 1;
        }

        inline fn reset(self: *Self) void {
            self.num_neighbours = 0;
        }
    };
}
