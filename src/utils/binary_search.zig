const std = @import("std");

const Order = std.math.Order;

fn compare_function(comptime T: type, want: T) fn (anytype, T) Order {
    return struct {
        pub fn cmp_fn(what: T) Order {
            if (what < want) {
                return .lt;
            } else if (what > want) {
                return .gt;
            } else {
                return .eq;
            }
        }
    }.cmp_fn;
}

pub fn binary_search(comptime T: type, values: []const T, compare_fn: fn (T) Order) ?usize {
    var low: usize = 0;
    var high: usize = values.len;

    while (low < high) {
        const mid: usize = low + (high - low) / 2;
        const value: T = values[mid];

        switch (compare_fn(value)) {
            .gt => high = mid,
            .lt => low = mid + 1,
            .eq => return mid,
        }
    }
    return null;
}

test "binary search" {
    const values = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

    const result = binary_search(u8, values[0..], compare_function(u8, 5));

    std.debug.assert(result == 5);
}
