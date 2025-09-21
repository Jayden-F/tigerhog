const std = @import("std");

pub fn BitGrid() type {
    return struct {
        const Self = @This();

        width: usize,
        height: usize,
        padded_width_bytes: usize,
        padded_width_bits: usize,
        data: std.bit_set.DynamicBitSet,

        pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
            const padded_width_bytes = width / 8 + 1;
            const padded_width_bits = padded_width_bytes * 8;
            const bits = padded_width_bits * (height + 2) + 8;
            const bytes = 8 + bits / 8 + 8;
            const size = bytes * 8;
            const data = try std.bit_set.DynamicBitSet.initEmpty(allocator, size);

            return .{ .width = width, .height = height, .padded_width_bytes = padded_width_bytes, .padded_width_bits = padded_width_bits, .data = data };
        }

        pub fn load_map(reader: *std.Io.Reader, allocator: std.mem.Allocator) !Self {
            _ = try reader.takeDelimiterExclusive('\n');
            const height_line = try reader.takeDelimiterExclusive('\n');
            const height = try std.fmt.parseInt(usize, height_line[7..], 10);
            const width_line = try reader.takeDelimiterExclusive('\n');
            const width = try std.fmt.parseInt(usize, width_line[6..], 10);
            _ = try reader.takeDelimiterExclusive('\n');

            var result = try init(allocator, width, height);

            for (0..height) |i| {
                const row_line = try reader.takeDelimiterExclusive('\n');
                for (0..width) |j| {
                    result.set(@intCast(j), @intCast(i), row_line[j] == '.');
                }
            }
            return result;
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub inline fn is_valid(self: *const Self, x: i32, y: i32) bool {
            const i = self.index(x, y);
            return self.data.isSet(i);
        }

        pub fn set(self: *Self, x: i32, y: i32, value: bool) void {
            const i = self.index(x, y);
            self.data.setValue(i, value);
        }

        inline fn index(self: *const Self, x: i32, y: i32) usize {
            const padded_y: u32 = @intCast(y + 1);
            const padded_x: u32 = @intCast(x + 1);

            const bit = padded_x & 7;
            const byte = (padded_x / 8 + padded_y * self.padded_width_bytes) + 8;
            return byte * 8 + bit;
        }
    };
}
