const std = @import("std");
const util = @import("util.zig");

const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const print = std.debug.print;

const data = @embedFile("data/day03.txt");
const data_test = @embedFile("data/day03.test.txt");

const Vec = struct {
    x: u32,
    y: u32,
};

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var map, const x_max, const y_max = try parseInput(input);
    defer map.deinit();

    return traverseMap(map, Vec{ .x = 3, .y = 1 }, Vec{ .x = x_max, .y = y_max });
}

fn partTwo(input: []const u8) !u32 {
    var map, const x_max, const y_max = try parseInput(input);
    defer map.deinit();

    const bounds = Vec{ .x = x_max, .y = y_max };
    var trees: u32 = 1;
    trees *= traverseMap(map, Vec{ .x = 3, .y = 1 }, bounds);
    trees *= traverseMap(map, Vec{ .x = 1, .y = 1 }, bounds);
    trees *= traverseMap(map, Vec{ .x = 5, .y = 1 }, bounds);
    trees *= traverseMap(map, Vec{ .x = 7, .y = 1 }, bounds);
    trees *= traverseMap(map, Vec{ .x = 1, .y = 2 }, bounds);
    return trees;
}

fn traverseMap(map: Map(Vec, void), slope: Vec, bounds: Vec) u32 {
    var trees: u32 = 0;
    var me = Vec{ .x = 0, .y = 0 };
    while (me.y < bounds.y) {
        me.x = (me.x + slope.x) % bounds.x;
        me.y += slope.y;
        if (map.contains(me))
            trees += 1;
    }
    return trees;
}

fn parseInput(input: []const u8) !struct { Map(Vec, void), u32, u32 } {
    var map = Map(Vec, void).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    var x: u32 = 0;
    var y: u32 = 0;
    while (lines.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            if (c == '#')
                try map.put(Vec{ .x = x, .y = y }, {});
            x += 1;
        }
    }
    return .{ map, x, y };
}
