const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

const data = @embedFile("data/day10.txt");
const data_test = @embedFile("data/day10.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    const adapters = try parseInput(input);
    defer adapters.deinit();

    var jolt_diffs = [3]u32{ 0, 0, 0 };
    for (1..adapters.items.len) |i| {
        jolt_diffs[adapters.items[i] - adapters.items[i - 1] - 1] += 1;
    }
    return jolt_diffs[0] * jolt_diffs[2];
}

fn partTwo(input: []const u8) !u64 {
    const adapters = try parseInput(input);
    defer adapters.deinit();

    var cache = Map(u8, u64).init(gpa);
    defer cache.deinit();
    return try dfs(adapters.items, &cache);
}

fn dfs(adapters: []const u8, cache: *Map(u8, u64)) !u64 {
    if (adapters.len == 1)
        return 1;

    const current = adapters[0];
    if (cache.contains(current))
        return cache.get(current).?;

    var combos: u64 = 0;
    for (1..@min(4, adapters.len)) |i| {
        const next = adapters[i];
        if (next - current > 3)
            break;
        combos += try dfs(adapters[i..], cache);
    }
    try cache.put(current, combos);
    return combos;
}

fn parseInput(input: []const u8) !List(u8) {
    var adapters = List(u8).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |adapter_str| {
        const adapter = try parseInt(u8, adapter_str, 10);
        try adapters.append(adapter);
    }
    try adapters.append(0);
    sort(u8, adapters.items, {}, asc(u8));
    try adapters.append(adapters.getLast() + 3);
    return adapters;
}
