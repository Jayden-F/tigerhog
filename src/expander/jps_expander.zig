const std = @import("std");
const direction = @import("../utils/direction.zig");

const N: u8 = 1 << @intFromEnum(direction.Direction.NORTH);
const E: u8 = 1 << @intFromEnum(direction.Direction.EAST);
const S: u8 = 1 << @intFromEnum(direction.Direction.SOUTH);
const W: u8 = 1 << @intFromEnum(direction.Direction.WEST);
const NE: u8 = 1 << @intFromEnum(direction.Direction.NORTH_EAST);
const SE: u8 = 1 << @intFromEnum(direction.Direction.SOUTH_EAST);
const SW: u8 = 1 << @intFromEnum(direction.Direction.SOUTH_WEST);
const NW: u8 = 1 << @intFromEnum(direction.Direction.NORTH_WEST);

fn get_direction(comptime State: type, parent: ?State, current: State) ?direction.Direction {
    if (parent) |par| {
        const p_x = par.get_x();
        const p_y = par.get_y();
        const x = current.get_x();
        const y = current.get_y();

        if (p_x == x and p_y > y)
            return .NORTH;
        if (p_x < x and p_y == y)
            return .EAST;
        if (p_x > x and p_y == y)
            return .WEST;
        if (p_x == x and p_y < y)
            return .SOUTH;
        if (p_x < x and p_y > y)
            return .NORTH_EAST;
        if (p_x < x and p_y < y)
            return .SOUTH_EAST;
        if (p_x > x and p_y < y)
            return .SOUTH_WEST;
        if (p_x > x and p_y > y)
            return .NORTH_WEST;
    }
    return null;
}

pub fn compute_orthogonal(f: u8, fl: u8, l: u8, bl: u8, fr: u8, r: u8, br: u8) [256]u8 {
    var result: [256]u8 = undefined;
    @memset(result[0..], 0);

    var nb: usize = 0;
    while (nb < 256) : (nb += 1) {
        if (nb & f != 0)
            result[nb] |= f;

        if (nb & (bl | l) == l) {
            result[nb] |= l;
            if (nb & (f | fl) == f | fl)
                result[nb] |= fl;
        }
        if (nb & (br | r) == r) {
            result[nb] |= r;
            if (nb & (f | fr) == f | fr)
                result[nb] |= fr;
        }
    }
    return result;
}

pub fn compute_diagonal(f: u8, l: u8, r: u8) [256]u8 {
    var result: [256]u8 = undefined;
    @memset(result[0..], 0);

    var nb: usize = 0;
    while (nb < 256) : (nb += 1) {
        if (nb & l != 0)
            result[nb] |= l;
        if (nb & r != 0)
            result[nb] |= r;
        if (nb & (f | l | r) == (f | l | r))
            result[nb] |= f;
    }
    return result;
}

pub fn compute_default() [256]u8 {
    var result: [256]u8 = undefined;
    @memset(result[0..], 0);

    var nb: usize = 0;
    while (nb < 256) : (nb += 1) {
        if (nb & N != 0)
            result[nb] |= N;
        if (nb & E != 0)
            result[nb] |= E;
        if (nb & S != 0)
            result[nb] |= S;
        if (nb & W != 0)
            result[nb] |= W;
        if (nb & (N | NE | E) == N | NE | E)
            result[nb] |= NE;
        if (nb & (E | SE | S) == E | SE | S)
            result[nb] |= SE;
        if (nb & (S | SW | W) == S | SW | W)
            result[nb] |= SW;
        if (nb & (W | NW | N) == W | NW | N)
            result[nb] |= NW;
    }
    return result;
}

pub fn CanonicalGridExpander(
    comptime Domain: type,
    comptime Node: type,
    comptime NodePool: type,
) type {
    const Neighbours = std.EnumSet(direction.Direction);

    const Edge = struct {
        node: *Node,
        cost: f64,
    };

    return struct {
        const Self = @This();

        domain: *Domain,
        node_pool: *NodePool,
        lookup: [8][256]u8 = init: {
            @setEvalBranchQuota(256 * 9 + 9);
            const result = .{
                compute_orthogonal(N, NW, W, SW, NE, E, SE),
                compute_orthogonal(E, NE, N, NW, SE, S, SW),
                compute_orthogonal(S, SE, E, NE, SW, W, NW),
                compute_orthogonal(W, SW, S, SE, NW, N, NE),
                compute_diagonal(NE, N, E),
                compute_diagonal(SE, E, S),
                compute_diagonal(SW, S, W),
                compute_diagonal(NW, W, N),
            };
            break :init result;
        },

        edges: [8]Edge = undefined,
        num_neighbours: usize = 0,

        default: [256]u8 = compute_default(),

        pub fn init(domain: *Domain, node_pool: *NodePool) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
            };
        }
        pub fn deinit(_: *Self) void {}

        pub inline fn get_neighbours(self: *const Self, x: i32, y: i32) Neighbours {
            var nb: Neighbours = Neighbours.initEmpty();

            if (self.domain.is_valid(x, y - 1))
                nb.insert(.NORTH);

            if (self.domain.is_valid(x + 1, y))
                nb.insert(.EAST);

            if (self.domain.is_valid(x, y + 1))
                nb.insert(.SOUTH);

            if (self.domain.is_valid(x - 1, y))
                nb.insert(.WEST);

            if (self.domain.is_valid(x + 1, y - 1))
                nb.insert(.NORTH_EAST);

            if (self.domain.is_valid(x + 1, y + 1))
                nb.insert(.SOUTH_EAST);

            if (self.domain.is_valid(x - 1, y + 1))
                nb.insert(.SOUTH_WEST);

            if (self.domain.is_valid(x - 1, y - 1))
                nb.insert(.NORTH_WEST);

            return nb;
        }

        pub fn expand(
            self: *Self,
            current: *Node,
        ) ![]const Edge {
            self.num_neighbours = 0;

            const current_state = current.get_state();

            const x: i32 = current_state.get_x();
            const y: i32 = current_state.get_y();

            std.debug.assert(self.domain.is_valid(x, y));

            const nb = self.get_neighbours(x, y);

            const parent: ?*Node = current.get_parent();
            const parent_state = if (parent) |par| par.get_state() else null;
            const maybe_dir = if (parent_state) |par| get_direction(Node.State_T, par, current_state) else null;

            var neighbours: Neighbours = undefined;
            neighbours.bits.mask = if (maybe_dir) |dir| self.lookup[@intFromEnum(dir)][nb.bits.mask] else self.default[nb.bits.mask];

            if (neighbours.contains(.NORTH))
                try self.add_neighbour(.{ .x = x, .y = y - 1 }, 1.0);

            if (neighbours.contains(.EAST))
                try self.add_neighbour(.{ .x = x + 1, .y = y }, 1.0);

            if (neighbours.contains(.SOUTH))
                try self.add_neighbour(.{ .x = x, .y = y + 1 }, 1.0);

            if (neighbours.contains(.WEST))
                try self.add_neighbour(.{ .x = x - 1, .y = y }, 1.0);

            if (neighbours.contains(.NORTH_EAST))
                try self.add_neighbour(.{ .x = x + 1, .y = y - 1 }, std.math.sqrt2);

            if (neighbours.contains(.SOUTH_EAST))
                try self.add_neighbour(.{ .x = x + 1, .y = y + 1 }, std.math.sqrt2);

            if (neighbours.contains(.SOUTH_WEST))
                try self.add_neighbour(.{ .x = x - 1, .y = y + 1 }, std.math.sqrt2);

            if (neighbours.contains(.NORTH_WEST))
                try self.add_neighbour(.{ .x = x - 1, .y = y - 1 }, std.math.sqrt2);

            return self.edges[0..self.num_neighbours];
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: f64) !void {
            const node: *Node = try self.generate(state);
            self.edges[self.num_neighbours] = .{ .node = node, .cost = cost };
            self.num_neighbours += 1;
        }

        pub inline fn generate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.generate(state);
        }

        pub inline fn reset(self: *Self) void {
            self.node_pool.reset();
        }
    };
}
