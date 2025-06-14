const std = @import("std");

const Ordering = enum {
    Less,
    Greater,
    Equal,
};

fn compare_function(comptime T: type, want: T) fn (T) Ordering {
    return struct {
        pub fn cmp_fn(what: T) Ordering {
            if (what < want) {
                return Ordering.Less;
            } else if (what > want) {
                return Ordering.Greater;
            } else {
                return Ordering.Equal;
            }
        }
    }.cmp_fn;
}

pub fn binary_search(comptime T: type, values: []T, compare_fn: fn (T) Ordering) usize {
    var low: usize = 0;
    var high: usize = 0;

    while (low < high) {
        const mid = low + (high - low) / 2;
        const value = values[mid];

        switch (compare_fn(value)) {
            .Greater => high = mid,
            .Less => low = mid + 1,
            .Equal => return mid,
        }
    }
    return low;
}
