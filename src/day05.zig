const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const sliceMax = std.mem.max;
const print = std.debug.print;
const sort = std.sort.block;
const asc = std.sort.asc;

const data = @embedFile("data/day05.txt");
const data_test = @embedFile("data/day05.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    // const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, 0 });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    const seat_ids = try parseSeatIds(input);
    defer seat_ids.deinit();
    return sliceMax(u32, seat_ids.items);
}

fn partTwo(input: []const u8) !u32 {
    const seat_ids = try parseSeatIds(input);
    defer seat_ids.deinit();

    sort(u32, seat_ids.items, {}, asc(u32));
    for (seat_ids.items[0 .. seat_ids.items.len - 1], 0..) |id, i| {
        if (id + 2 == seat_ids.items[i + 1])
            return id + 1;
    }
    return error.NoSolution;
}

fn parseSeatIds(input: []const u8) !List(u32) {
    var seat_ids = List(u32).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |seat| {
        const row, const col = try binarySpacePartition(seat);
        // print("{d},{d}\n", .{ row, col });
        const seat_id = row * 8 + col;
        try seat_ids.append(seat_id);
    }
    return seat_ids;
}

fn binarySpacePartition(seat: []const u8) ![2]u32 {
    var row_lo: u32 = 0;
    var row_hi: u32 = 127;
    for (seat[0..6]) |c| {
        const mid = (row_lo + row_hi) / 2;
        switch (c) {
            'F' => row_hi = mid,
            'B' => row_lo = mid + 1,
            else => return error.InvalidChar,
        }
    }
    const row = if (seat[6] == 'F') row_lo else row_hi;

    var col_lo: u32 = 0;
    var col_hi: u32 = 7;
    for (seat[7 .. seat.len - 1]) |c| {
        const mid = (col_lo + col_hi) / 2;
        switch (c) {
            'L' => col_hi = mid,
            'R' => col_lo = mid + 1,
            else => return error.InvalidChar,
        }
    }
    const col = if (seat[seat.len - 1] == 'L') col_lo else col_hi;

    return .{ row, col };
}
