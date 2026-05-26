const std = @import("std");
const node_pool = @import("node_pool.zig");
const hash_mapper = @import("hash_mapper.zig");
const grid_mapper = @import("grid_mapper.zig");
const binned_grid_mapper = @import("./binned_grid_mapper.zig");

pub const NodePool = node_pool.NodePool;
pub const HashMapper = hash_mapper.HashMapper;
pub const GridMapper = grid_mapper.GridMapper;
pub const BinnedGridMapper = binned_grid_mapper.BinnedGridMapper;

pub fn HashNodePool(comptime State: type, comptime Node: type) type {
    return NodePool(HashMapper(State, Node), Node, State, std.heap.memory_pool.Managed(Node));
}

pub fn GridNodePool(comptime State: type, comptime Node: type) type {
    return NodePool(GridMapper(State, Node), Node, State, std.heap.memory_pool.Managed(Node));
}

pub fn BinnedGridNodePool(comptime State: type, comptime Node: type) type {
    return NodePool(BinnedGridMapper(State, Node), Node, State, std.heap.memory_pool.Managed(Node));
}

pub fn GridPool(comptime State: type, comptime Node: type) type {
    return GridNodePool(State, Node);
}
