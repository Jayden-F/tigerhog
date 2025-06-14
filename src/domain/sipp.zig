const std = @import("std");
const binary_search = @import("../utils/binary_search.zig");

const Action = enum {
    North,
    East,
    South,
    West,
    Wait,
};

const Interval = struct {
    s_time: f64,
    e_time: f64,
    action: Action,
};

const SIPP_Interval = union(enum) {
    safe: Interval,
    unsafe: Interval,
};




const SIPP_Intervals = struct {
    const Self = @This();

    reservations: []SIPP_Interval,

    pub fn find_interval(self: *const Self) usize {
        const result = binary_search.binary_search(SIPP_Interval, self.reservations, compare_fn);
        return result;
    }
};

const SIPP_Table = struct {
    locations: []SIPP_Intervals,
};
