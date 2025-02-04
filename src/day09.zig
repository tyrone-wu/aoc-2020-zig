const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day09.txt");
const data_test = @embedFile("data/day09.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test, 5);
    const p2_test = try partTwo(data_test, 5);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data, 25);
    const p2 = try partTwo(data, 25);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8, preamble: u8) !i64 {
    const xmas_data = try parseInput(input);
    defer xmas_data.deinit();
    return try findInvalidNumber(xmas_data.items, preamble);
}

fn partTwo(input: []const u8, preamble: u8) !i64 {
    const xmas_data = try parseInput(input);
    defer xmas_data.deinit();

    const invalid_num = try findInvalidNumber(xmas_data.items, preamble);
    for (2..xmas_data.items.len) |size| {
        const i = findEncryptionWeakness(xmas_data.items, invalid_num, size) orelse continue;
        var min = xmas_data.items[i - size];
        var max = min;
        for (xmas_data.items[i - size .. i]) |num| {
            min = @min(min, num);
            max = @max(max, num);
        }
        return min + max;
    }
    return error.NoSolution;
}

fn findEncryptionWeakness(xmas_data: []const i64, target: i64, window_size: usize) ?usize {
    var window_sum: i64 = 0;
    for (xmas_data[0..window_size]) |num| {
        window_sum += num;
    }
    if (window_size == target)
        return window_size;

    for (window_size..xmas_data.len) |i| {
        window_sum += xmas_data[i] - xmas_data[i - window_size];
        if (window_sum == target)
            return i + 1;
    }
    return null;
}

fn findInvalidNumber(xmas_data: []const i64, preamble: u8) !i64 {
    for (0..xmas_data.len - (preamble + 1)) |i| {
        const target = xmas_data[i + preamble];
        if (try twoSum(xmas_data[i .. i + preamble], target))
            return target;
    }
    return error.NoSolution;
}

fn twoSum(xmas_data: []const i64, target: i64) !bool {
    var seen = Map(i64, void).init(gpa);
    defer seen.deinit();

    for (xmas_data) |num| {
        if (seen.contains(target - num))
            return false;
        try seen.put(num, {});
    }
    return true;
}

fn parseInput(input: []const u8) !List(i64) {
    var xmas_data = List(i64).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |num| {
        try xmas_data.append(try parseInt(i64, num, 10));
    }
    return xmas_data;
}
