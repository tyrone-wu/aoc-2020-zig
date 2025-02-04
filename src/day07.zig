const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const StrMap = std.StringHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const splitSeq = std.mem.splitSequence;
const indexOf = std.mem.indexOfScalar;
const lastIndexOf = std.mem.lastIndexOfScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const equals = std.mem.eql;
const startsWith = std.mem.startsWith;

const data = @embedFile("data/day07.txt");
const data_test_p1 = @embedFile("data/day07.test.p1.txt");
const data_test_p2 = @embedFile("data/day07.test.p2.txt");

const Bag = struct {
    quantity: u32,
    color: []const u8,
};

pub fn main() !void {
    const p1_test = try partOne(data_test_p1);
    const p2_test = try partTwo(data_test_p2);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var rules = try parseInput(input);
    defer {
        var contains_it = rules.valueIterator();
        while (contains_it.next()) |contains| {
            contains.deinit();
        }
        rules.deinit();
    }

    var shiny_gold = StrMap(void).init(gpa);
    defer shiny_gold.deinit();

    var color_it = rules.keyIterator();
    while (color_it.next()) |color| {
        _ = try dfs(rules, color.*, &shiny_gold);
    }
    return shiny_gold.count();
}

fn dfs(rules: StrMap(List(Bag)), color: []const u8, shiny_gold: *StrMap(void)) !bool {
    if (equals(u8, color, "shiny gold") or shiny_gold.contains(color))
        return true;

    var contains_shiny = false;
    for (rules.get(color).?.items) |bag|
        contains_shiny = contains_shiny or try dfs(rules, bag.color, shiny_gold);
    if (contains_shiny)
        try shiny_gold.put(color, {});
    return contains_shiny;
}

fn partTwo(input: []const u8) !u32 {
    var rules = try parseInput(input);
    defer {
        var contains_it = rules.valueIterator();
        while (contains_it.next()) |contains| {
            contains.deinit();
        }
        rules.deinit();
    }

    return try dfsP2(rules, "shiny gold") - 1;
}

fn dfsP2(rules: StrMap(List(Bag)), color: []const u8) !u32 {
    var bags: u32 = 1;
    for (rules.get(color).?.items) |bag|
        bags += bag.quantity * try dfsP2(rules, bag.color);
    return bags;
}

fn parseInput(input: []const u8) !StrMap(List(Bag)) {
    var rules = StrMap(List(Bag)).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |rule| {
        var rule_it = splitSeq(u8, rule, " bags contain ");
        const color = rule_it.next().?;

        var contains_it = splitSeq(u8, rule_it.next().?, ", ");
        var contains = List(Bag).init(gpa);
        while (contains_it.next()) |bag| {
            if (startsWith(u8, bag, "no"))
                continue;

            const s = indexOf(u8, bag, ' ').?;
            const quantity = try parseInt(u32, bag[0..s], 10);
            const bag_color = bag[s + 1 .. lastIndexOf(u8, bag, ' ').?];
            try contains.append(Bag{ .quantity = quantity, .color = bag_color });
        }

        try rules.put(color, contains);
    }
    return rules;
}
