fn reverse(arr: anytype) void {
    const len = arr.len;

    var i: usize = 0;
    var j: usize = len - 1;
    while (i < j) {
        const temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
        i += 1;
        j -= 1;
    }
}
