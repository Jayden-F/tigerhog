const std = @import("std");

const PriorityQueueError = error{
    QueueEmpty,
};

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        priority: usize = std.math.maxInt(usize),

        // Getter method for the priority field
        pub fn get_priority(self: *const Self) usize {
            return self.priority;
        }

        // Setter method for the priority field
        pub fn set_priority(self: *Self, value: usize) void {
            self.priority = value;
        }
    };
}

pub fn PriorityQueue(comptime T: type, comptime compare_fn: fn (T, T) bool) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        elements: []T,
        capacity: u64,
        len: u64 = 0,
        heap_ops: u64 = 0,

        pub fn empty(self: *Self) bool {
            return self.len == 0;
        }

        pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            const elements: []T = try allocator.alloc(T, capacity);
            return Self{
                .allocator = allocator,
                .elements = elements,
                .capacity = capacity,
                .len = 0,
                .heap_ops = 0,
            };
        }

        pub fn build(allocator: std.mem.Allocator, from: []const T) !Self {
            const elements = try allocator.dupe(T, from);
            var self = Self{
                .allocator = allocator,
                .elements = elements,
                .capacity = elements.len,
                .len = elements.len,
                .heap_ops = 0,
            };

            for (self.elements, 0..) |*elem, idx| {
                elem.set_priority(idx);
            }

            const n = self.len >> 1;
            var i = n;
            while (i <= n) : (i -%= 1) {
                self.sift_down(i);
            }

            return self;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.elements);
            self.capacity = 0;
            self.len = 0;
        }

        pub fn reset(self: *Self) void {
            self.len = 0;
            self.heap_ops = 0;
        }

        pub fn push_assume_cap(self: *Self, value: T) void {
            if (self.contains(value)) {
                self.decrease_key(value);
                return;
            }
            value.set_priority(self.len);
            self.elements[self.len] = value;
            self.sift_up(self.len);
            self.len += 1;
        }

        pub fn push(self: *Self, value: T) !void {
            if (self.contains(value)) {
                self.decrease_key(value);
                return;
            }
            const new_len = self.len + 1;
            if (new_len > self.capacity) {
                try self.grow(self.capacity * 2);
            }
            value.set_priority(self.len);
            self.elements[self.len] = value;
            self.sift_up(self.len);
            self.len = new_len;
        }

        pub fn unchecked_pop(self: *Self) T {
            self.len -= 1;
            self.swap(0, self.len);
            self.sift_down(0);
            self.elements[self.len].set_priority(std.math.maxInt(usize));
            return self.elements[self.len];
        }

        pub fn pop(self: *Self) PriorityQueueError!T {
            switch (self.len) {
                0 => {
                    return PriorityQueueError.QueueEmpty;
                },
                else => {
                    return self.unchecked_pop();
                },
            }
        }

        pub fn peek(self: *Self) T {
            switch (self.len) {
                0 => return PriorityQueueError.QueueEmpty,
                else => return self.elements[0],
            }
        }

        pub fn decrease_key(self: *Self, value: T) void {
            std.debug.assert(self.contains(value));
            self.sift_up(value.get_priority());
        }

        pub fn increase_key(self: *Self, value: T) void {
            std.debug.assert(self.contains(value));
            self.sift_down(value.get_priority());
        }

        pub fn grow(self: *Self, new_capacity: usize) !void {
            @setRuntimeSafety(false);
            if (new_capacity <= self.capacity) {
                return;
            }
            const new_elements: []T = try self.allocator.realloc(self.elements, new_capacity);
            self.elements = new_elements;
            self.capacity = new_capacity;
        }

        pub fn size(self: *Self) usize {
            return @sizeOf(Self) + self.capacity * @sizeOf(T);
        }

        pub inline fn contains(self: *const Self, value: T) bool {
            const priority = value.get_priority();
            if (priority < self.len) {
                return std.meta.eql(value, self.elements[priority]);
            }
            return false;
        }

        inline fn sift_up(self: *Self, index: usize) void {
            @setRuntimeSafety(false);
            self.heap_ops += 1;

            var current = index;
            const item = self.elements[current];

            while (current > 0) {
                const parent = (current - 1) >> 1;
                const parent_item = self.elements[parent];

                if (!compare_fn(item, parent_item)) break;

                self.elements[current] = parent_item;
                self.elements[current].set_priority(current);
                current = parent;
            }

            self.elements[current] = item;
            self.elements[current].set_priority(current);
        }

        inline fn sift_down(self: *Self, index: usize) void {
            @setRuntimeSafety(false);
            self.heap_ops += 1;

            const len = self.len;

            var current = index;
            const item = self.elements[current];

            const first_leaf_index = len >> 1;

            while (current < first_leaf_index) {
                const left = (current << 1) + 1;
                const right = left + 1;

                var child = left;
                var child_item = self.elements[left];

                if (right < len) {
                    const right_item = self.elements[right];
                    if (compare_fn(right_item, child_item)) {
                        child = right;
                        child_item = right_item;
                    }
                }

                if (!compare_fn(child_item, item)) break;

                self.elements[current] = child_item;
                self.elements[current].set_priority(current);
                current = child;
            }

            self.elements[current] = item;
            self.elements[current].set_priority(current);
        }

        inline fn swap(self: *Self, a: usize, b: usize) void {
            @setRuntimeSafety(false);
            const temp = self.elements[b];
            self.elements[b] = self.elements[a];
            self.elements[a] = temp;
            self.elements[a].set_priority(a);
            self.elements[b].set_priority(b);
        }
    };
}

const Node_u64 = Node(u64);

fn lessThanPtr(a: *Node_u64, b: *Node_u64) bool {
    return a.value < b.value;
}

fn lessThan(a: Node_u64, b: Node_u64) bool {
    return a.value < b.value;
}

test "test priority queue" {
    const allocator = std.testing.allocator;
    const Queue = PriorityQueue(*Node_u64, lessThanPtr);

    var queue = try Queue.init(allocator, 1);
    defer queue.deinit();

    var n: u64 = 1_000_000;
    var nodes = try allocator.alloc(Node_u64, n);
    defer allocator.free(nodes);
    while (n > 0) : (n -= 1) {
        nodes[n - 1].value = n;
        try queue.push(&nodes[n - 1]);
        std.debug.assert(queue.contains(&nodes[n - 1]));
    }

    while (queue.len > 0) {
        const node = try queue.pop();
        // std.debug.print("{}\n", .{node});
        std.debug.assert(!queue.contains(node));
    }
}

test "test build priority queue" {
    const allocator = std.testing.allocator;
    const Queue = PriorityQueue(Node_u64, lessThan);

    var n: u64 = 1_000_000;
    var nodes = try allocator.alloc(Node_u64, n);
    defer allocator.free(nodes);

    while (n > 1) : (n -= 1) {
        nodes[n - 1].value = n;
    }

    var queue = try Queue.build(allocator, nodes);
    defer queue.deinit();

    while (queue.len > 0) {
        const node = try queue.pop();
        std.debug.assert(!queue.contains(node));
    }
}
