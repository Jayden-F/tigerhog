const std = @import("std");
const direction = @import("../utils/direction.zig");
const enum_set = @import("../utils/enum_set.zig");

pub fn GridExpander8Connected(comptime State: type, comptime Domain: type, comptime NodeMapper: type) type {
    const Direction = direction.Direction;
    const Neighbours = enum_set.EnumSet(Direction);

    const Edge = struct {
        state: State,
        cost: f64,
    };

    return struct {
        const Self = @This();

        domain: *Domain,
        node_mapper: *NodeMapper,
        edges: [4]Edge = undefined,
        num_neighbours: usize = 0,
        goal_state: ?State = null,

        pub fn init(domain: *Domain, map: *NodeMapper) Self {
            return .{
                .domain = domain,
                .node_mapper = map,
            };
        }

        pub fn get_neighbours(self: *const Self, x: i32, y: i32) Neighbours {
            var result = Neighbours.init();

            const north = self.domain.is_valid(x, y - 1);
            if (north) result.insert(Direction.NORTH);
            const south = self.domain.is_valid(x, y + 1);
            if (south) result.insert(Direction.SOUTH);

            if (self.domain.is_valid(x + 1, y)) {
                result.insert(Direction.EAST);

                if (north and self.domain.is_valid(x + 1, y - 1)) {
                    result.insert(Direction.NORTH_EAST);
                }
                if (south and self.domain.is_valid(x + 1, y + 1)) {
                    result.insert(Direction.SOUTH_EAST);
                }
            }

            if (self.domain.is_valid(x - 1, y)) {
                result.insert(Direction.WEST);

                if (north and self.domain.is_valid(x - 1, y - 1)) {
                    result.insert(Direction.NORTH_WEST);
                }

                if (south and self.domain.is_valid(x - 1, y + 1)) {
                    result.insert(Direction.SOUTH_WEST);
                }
            }
            return result;
        }

        pub fn expand(self: *Self, current: State) []Edge {
            self.reset();

            const x: i32 = current.get_x();
            const y: i32 = current.get_y();

            std.debug.assert(self.domain.is_valid(x, y));

            const neighbours = self.get_neighbours(x, y);

            if (neighbours.contains(Direction.NORTH)) {
                self.add_neighbour(.{ .x = x, .y = y - 1 }, 1.0);
            }

            if (neighbours.contains(Direction.NORTH)) {
                self.add_neighbour(.{ .x = x, .y = y - 1 }, 1.0);
            }

            if (neighbours.contains(Direction.EAST)) {
                self.add_neighbour(.{ .x = x + 1, .y = y }, 1.0);
            }

            if (neighbours.contains(Direction.SOUTH)) {
                self.add_neighbour(.{ .x = x, .y = y + 1 }, 1.0);
            }

            if (neighbours.contains(Direction.WEST)) {
                self.add_neighbour(.{ .x = x - 1, .y = y }, 1.0);
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
