const std = @import("std");

pub fn GridMapper(comptime State: type, comptime Node: type) type {
    return struct {
        const Self = @This();
        const Slot = struct {
            generation: usize,
            node: ?*Node,
        };

        width: usize,
        height: usize,
        allocator: std.mem.Allocator,
        slots: []Slot,
        generation: usize = 1,

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
            var slots = try allocator.alloc(Slot, width * height);
            @memset(slots[0..], .{ .generation = 0, .node = null });

            return .{
                .width = width,
                .height = height,
                .allocator = allocator,
                .slots = slots,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.slots);
        }

        pub fn reset(self: *Self) void {
            self.generation +%= 1;
        }

        inline fn getIndex(self: *const Self, state: State) usize {
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

        pub fn get(self: *Self, state: State) !*?*Node {
            const index = self.getIndex(state);
            const slot = &self.slots[index];
            if (slot.generation != self.generation) {
                slot.* = .{ .generation = self.generation, .node = null };
            }
            return &slot.node;
        }
    };
}
