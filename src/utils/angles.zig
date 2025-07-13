pub fn wrap_angle(angle: f64, lower: f64, upper: f64) f64 {
    return @mod(angle - lower, upper - lower) + lower;
}
