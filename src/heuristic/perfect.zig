const std = @import("std");

const ZeroT = @import("zero.zig").Zero;

pub fn LookupHeuristic(comptime State: type) type {
    return struct {
        const Self = @This();
        const Cost = f64;

        width: usize,
        height: usize,
        table: []Cost,
        allocator: std.mem.Allocator,

        fn get_index(self: *const Self, state: State) usize {
            const x: usize = switch (@typeInfo(@TypeOf(state.get_x()))) {
                .float => @intFromFloat(state.get_x()),
                .int => @intCast(state.get_x()),
                else => @compileError("Unsupported type for get_x()"),
            };

            const y: usize = switch (@typeInfo(@TypeOf(state.get_y()))) {
                .float => @intFromFloat(state.get_y()),
                .int => @intCast(state.get_y()),
                else => @compileError("Unsupported type for get_y()"),
            };

            return y * self.width + x;
        }

        pub fn init(width: usize, height: usize, table: []Cost, allocator: std.mem.Allocator) Self {
            return .{
                .height = height,
                .width = width,
                .table = table,
                .allocator = allocator,
            };
        }
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.table);
        }

        pub fn compute(self: *Self, current: State, _: ?State) Cost {
            const index: usize = self.get_index(current);
            return self.table[index];
        }
    };
}

pub fn CostLoggerT(comptime Node: type) type {
    return struct {
        const Self = @This();
        const Cost = f64;

        width: usize,
        height: usize,
        table: ?[]Cost,
        allocator: std.mem.Allocator,

        fn get_index(self: *const Self, state: Node.State_T) usize {
            const x: usize = switch (@typeInfo(@TypeOf(state.get_x()))) {
                .float => @intFromFloat(state.get_x()),
                .int => @intCast(state.get_x()),
                else => @compileError("Unsupported type for get_x()"),
            };

            const y: usize = switch (@typeInfo(@TypeOf(state.get_y()))) {
                .float => @intFromFloat(state.get_y()),
                .int => @intCast(state.get_y()),
                else => @compileError("Unsupported type for get_y()"),
            };
            return y * self.width + x;
        }

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            const table = try allocator.alloc(Cost, height * width);
            @memset(table, std.math.inf(Cost));

            return .{
                .height = height,
                .width = width,
                .table = table,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            // clean up in the case the table has not been handed off to a heuristic
            if (self.table) |table| {
                self.allocator.free(table);
            }
        }

        pub fn initialise(_: *Self, _: *const Node, _: ?*const Node) !void {}

        pub fn generate(_: *Self, _: *const Node) !void {}

        pub fn expand(self: *Self, node: *const Node) !void {
            const index = self.get_index(node.get_state());
            self.table.?[index] = node.get_g();
        }

        pub fn close(_: *Self, _: *const Node) !void {}

        pub fn get_table(self: *Self) []Cost {
            const result = self.table.?[0..];
            self.table = null;
            return result;
        }
    };
}
