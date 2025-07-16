pub fn wrap(comptime T: type, value: T, lower: T, upper: T) T {
    return @mod(value - lower, upper - lower) + lower;
}
