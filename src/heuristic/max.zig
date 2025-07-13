const std = @import("std");

pub fn Max(comptime State: type) type {
    const Heuristic = struct {
        ptr: *anyopaque,
        computeFn: *const fn (ctx: *anyopaque, start: State, target: ?State) f64,

        pub fn compute(self: @This(), start: State, target: ?State) f64 {
            return self.computeFn(self.ptr, start, target);
        }
    };

    return struct {
        heuristics: std.ArrayList(Heuristic),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .heuristics = std.ArrayList(Heuristic).init(allocator) };
        }

        pub fn add(self: *Self, ptr: anytype) !void {
            try self.heuristics.append(.{ .ptr = ptr, .computeFn = struct {
                fn computeWrapper(ctx: *anyopaque, start: State, target: ?State) f64 {
                    return @as(@TypeOf(ptr), @ptrCast(@alignCast(ctx))).compute(start, target);
                }
            }.computeWrapper });
        }

        pub fn compute(self: *Self, start: State, target: ?State) f64 {
            var max: f64 = 0;
            for (self.heuristics.items) |h| {
                const value = h.compute(start, target);
                max = @max(max, value);
            }
            return max;
        }

        pub fn deinit(self: *Self) void {
            self.heuristics.deinit();
        }
    };
}
