const std = @import("std");
const util = @import("util.zig");

const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day15.txt");
const data_test = @embedFile("data/day15.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    return try playMemoryGame(input, 2020);
}

fn partTwo(input: []const u8) !u32 {
    return try playMemoryGame(input, 30000000);
}

fn playMemoryGame(input: []const u8, end: u32) !u32 {
    var numbers, var last_spoken = try parseInput(input);
    defer numbers.deinit();

    var last_spoken_turn: ?u32 = null;
    var turn: u32 = numbers.count() + 1;
    while (turn <= end) : (turn += 1) {
        last_spoken = if (last_spoken_turn) |t| numbers.get(last_spoken).? - t else 0;
        last_spoken_turn = numbers.get(last_spoken);
        try numbers.put(last_spoken, turn);
    }
    return last_spoken;
}

fn parseInput(input: []const u8) !struct { Map(u32, u32), u32 } {
    var numbers = Map(u32, u32).init(gpa);
    var tokens = tokenizeAny(u8, input, ",\n");
    var i: u32 = 1;
    var last_spoken: u32 = 0;
    while (tokens.next()) |num_str| : (i += 1) {
        last_spoken = try parseInt(u32, num_str, 10);
        try numbers.put(last_spoken, i);
    }
    return .{ numbers, last_spoken };
}
