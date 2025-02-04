const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.indexOfScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day18.txt");
const data_test = @embedFile("data/day18.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u64 {
    var lines = tokenizeSca(u8, input, '\n');
    var sum: u64 = 0;
    while (lines.next()) |expression_str| {
        const result, _ = try dfs(expression_str);
        // print("{d}\n", .{result});
        sum += result;
    }
    return sum;
}

fn partTwo(input: []const u8) !u64 {
    var lines = tokenizeSca(u8, input, '\n');
    var sum: u64 = 0;
    while (lines.next()) |expression_str| {
        const result, _ = try dfsP2(expression_str);
        // print("{d}\n", .{result});
        sum += result;
    }
    return sum;
}

fn dfs(expression_str: []const u8) !struct { u64, usize } {
    var lhs: u64 = 0;
    var add = true;
    var i: usize = 0;
    while (i < expression_str.len) : (i += 1) {
        const c = expression_str[i];
        switch (c) {
            '(' => {
                const rhs, const j = try dfs(expression_str[i + 1 ..]);
                i += j;
                if (add) {
                    lhs += rhs;
                } else {
                    lhs *= rhs;
                }
            },
            ')' => return .{ lhs, i + 1 },
            ' ' => {},
            '+', '*' => add = c == '+',
            else => {
                var j = i;
                while (j + 1 < expression_str.len and expression_str[j + 1] != ' ' and expression_str[j + 1] != ')') : (j += 1) {}

                const rhs = try parseInt(u64, expression_str[i .. j + 1], 10);
                if (add) {
                    lhs += rhs;
                } else {
                    lhs *= rhs;
                }
                i = j;
            },
        }
    }
    return .{ lhs, i };
}

fn dfsP2(expression_str: []const u8) !struct { u64, usize } {
    var products = List(u64).init(gpa);
    defer products.deinit();
    try products.append(0);

    var add = true;
    var i: usize = 0;
    while (i < expression_str.len) : (i += 1) {
        const c = expression_str[i];
        switch (c) {
            '(' => {
                const rhs, const j = try dfsP2(expression_str[i + 1 ..]);
                i += j;
                if (add) {
                    products.items[products.items.len - 1] += rhs;
                } else {
                    try products.append(rhs);
                }
            },
            ')' => {
                var result: u64 = 1;
                for (products.items) |p| {
                    result *= p;
                }
                return .{ result, i + 1 };
            },
            ' ' => {},
            '+', '*' => add = c == '+',
            else => {
                var j = i;
                while (j + 1 < expression_str.len and expression_str[j + 1] != ' ' and expression_str[j + 1] != ')') : (j += 1) {}

                const rhs = try parseInt(u64, expression_str[i .. j + 1], 10);
                if (add) {
                    products.items[products.items.len - 1] += rhs;
                } else {
                    try products.append(rhs);
                }
                i = j;
            },
        }
    }

    var result: u64 = 1;
    for (products.items) |p| {
        result *= p;
    }
    return .{ result, i };
}
