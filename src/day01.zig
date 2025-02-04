const std = @import("std");
const util = @import("util.zig");

const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const assert = std.debug.assert;

const data = @embedFile("data/day01.txt");
const data_test = @embedFile("data/day01.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    assert(p1_test == 514579);
    const p1 = try partOne(data);

    const p2_test = try partTwo(data_test);
    assert(p2_test == 241861950);
    const p2 = try partTwo(data);

    print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    const target: u32 = 2020;
    var expense_report = Map(u32, void).init(gpa);
    defer expense_report.deinit();

    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        const expense = try parseInt(u32, line, 10);
        try expense_report.put(expense, {});
    }

    const a, const b = try twoSum(target, expense_report, null);
    return a * b;
}

fn partTwo(input: []const u8) !u32 {
    const target_main: u32 = 2020;
    var expense_report = Map(u32, void).init(gpa);
    defer expense_report.deinit();

    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        const expense = try parseInt(u32, line, 10);
        const target = target_main - expense;
        const a, const b = twoSum(target, expense_report, expense) catch {
            try expense_report.put(expense, {});
            continue;
        };
        return expense * a * b;
    }
    return error.NoSolution;
}

fn twoSum(target: u32, expense_report: Map(u32, void), ignore: ?u32) ![2]u32 {
    var it = expense_report.keyIterator();
    while (it.next()) |expense| {
        if (target < expense.*)
            continue;

        const other = target - expense.*;
        if (ignore != null and ((expense.* == ignore) or (other == ignore)))
            continue;

        if (expense_report.contains(other)) {
            return .{ expense.*, other };
        }
    }
    return error.NoSolution;
}
