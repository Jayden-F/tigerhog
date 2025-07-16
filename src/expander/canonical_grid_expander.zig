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

inline fn get_direction(comptime State: type, from: State, to: State) ?direction.Direction {
    const p_x = from.get_x();
    const p_y = from.get_y();
    const x = to.get_x();
    const y = to.get_y();

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

    return null;
}

inline fn get_reached_direction(comptime Node: type, from: *const Node, to: *const Node) ?direction.Direction {
    return get_direction(Node.State_T, from.get_state(), to.get_state());
}

pub fn compute_orthogonal(f: u8, fl: u8, l: u8, bl: u8, fr: u8, r: u8, br: u8) [256]u8 {
    var result: [256]u8 = undefined;
    @memset(result[0..], 0);

    inline for (0..256) |nb| {
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

    inline for (0..256) |nb| {
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

    inline for (0..256) |nb| {
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
        state: Node.State_T,
        node: *Node,
        cost: f64,
    };

    return struct {
        const Self = @This();
        const offsets = [_]struct { dx: i32, dy: i32, dir: direction.Direction, cost: f64 }{
            .{ .dx = 0, .dy = -1, .dir = .NORTH, .cost = 1.0 },
            .{ .dx = 1, .dy = 0, .dir = .EAST, .cost = 1.0 },
            .{ .dx = 0, .dy = 1, .dir = .SOUTH, .cost = 1.0 },
            .{ .dx = -1, .dy = 0, .dir = .WEST, .cost = 1.0 },
            .{ .dx = 1, .dy = -1, .dir = .NORTH_EAST, .cost = std.math.sqrt2 },
            .{ .dx = 1, .dy = 1, .dir = .SOUTH_EAST, .cost = std.math.sqrt2 },
            .{ .dx = -1, .dy = 1, .dir = .SOUTH_WEST, .cost = std.math.sqrt2 },
            .{ .dx = -1, .dy = -1, .dir = .NORTH_WEST, .cost = std.math.sqrt2 },
        };
        const lookup: [8][256]u8 = init: {
            @setEvalBranchQuota(9 * 256 + 9);
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
        };
        const default: [256]u8 = compute_default();

        domain: *Domain,
        node_pool: *NodePool,
        edges: [8]Edge = undefined,
        num_neighbours: usize = 0,

        pub fn init(domain: *Domain, node_pool: *NodePool) Self {
            return .{
                .domain = domain,
                .node_pool = node_pool,
            };
        }
        pub fn deinit(_: *Self) void {}

        pub inline fn reset(self: *Self) void {
            self.node_pool.reset();
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

            const neighbours = self.get_neighbours(x, y);
            const reached_dir: ?direction.Direction = if (current.get_parent()) |parent| get_reached_direction(Node, parent, current) else null;
            const successors = get_successors(neighbours, reached_dir);

            inline for (offsets) |offset| {
                if (successors.contains(offset.dir))
                    try self.add_neighbour(
                        .{
                            .x = x + offset.dx,
                            .y = y + offset.dy,
                        },
                        offset.cost,
                    );
            }

            return self.edges[0..self.num_neighbours];
        }

        pub inline fn generate(self: *Self, state: Node.State_T) !*Node {
            return try self.node_pool.generate(state);
        }

        inline fn get_neighbours(self: *const Self, x: i32, y: i32) Neighbours {
            var nb: Neighbours = Neighbours.initEmpty();

            inline for (offsets) |offset| {
                if (self.domain.is_valid(x + offset.dx, y + offset.dy))
                    nb.insert(offset.dir);
            }

            return nb;
        }

        inline fn get_successors(nb: Neighbours, reached_dir: ?direction.Direction) Neighbours {
            var successors: Neighbours = undefined;
            successors.bits.mask = if (reached_dir) |dir| lookup[@intFromEnum(dir)][nb.bits.mask] else default[nb.bits.mask];
            return successors;
        }

        inline fn add_neighbour(self: *Self, state: Node.State_T, cost: f64) !void {
            const node: *Node = try self.generate(state);
            self.edges[self.num_neighbours] = .{ .state = state, .node = node, .cost = cost };
            self.num_neighbours += 1;
        }
    };
}
