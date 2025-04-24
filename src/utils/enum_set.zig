const std = @import("std");

pub fn EnumSet(comptime E: type) type {
    const info = @typeInfo(E);
    const count = comptime info.@"enum".fields.len;

    return struct {
        const Self = @This();
        const BitSet = std.bit_set.StaticBitSet(count);

        bits: BitSet,

        pub inline fn init() Self {
            return .{ .bits = BitSet.initEmpty() };
        }

        pub inline fn insert(self: *Self, e: E) void {
            self.bits.set(@intFromEnum(e));
        }

        pub inline fn remove(self: *Self, e: E) void {
            self.bits.unset(@intFromEnum(e));
        }

        pub inline fn contains(self: Self, e: E) bool {
            return self.bits.isSet(@intFromEnum(e));
        }

        pub inline fn toggle(self: *Self, e: E) void {
            self.bits.toggle(@intFromEnum(e));
        }

        pub inline fn clear(self: *Self) void {
            self.bits = BitSet.initEmpty();
        }
    };
}
