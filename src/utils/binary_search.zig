const std = @import("std");

const Order = std.math.Order;

fn compare_function(comptime T: type, want: T) fn (T) Order {
    return struct {
        pub inline fn cmp_fn(what: T) Order {
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

pub fn binary_search(comptime T: type, values: []T, compare_fn: fn (T) Order) usize {
    var low: usize = 0;
    var high: usize = 0;

    while (low < high) {
        const mid: usize = low + (high - low) / 2;
        const value: T = values[mid];

        switch (compare_fn(value)) {
            .gt => high = mid,
            .lt => low = mid + 1,
            .eq => return mid,
        }
    }
    return low;
}
