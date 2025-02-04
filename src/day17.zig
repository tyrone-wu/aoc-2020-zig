const std = @import("std");
const util = @import("util.zig");

// const Allocator = std.mem.Allocator;
// const List = std.ArrayList;
const Map = std.AutoHashMap;
// const StrMap = std.StringHashMap;
// const BitSet = std.DynamicBitSet;

const gpa = util.gpa;

// // Useful stdlib functions
// const tokenizeAny = std.mem.tokenizeAny;
// const tokenizeSeq = std.mem.tokenizeSequence;
// const tokenizeSca = std.mem.tokenizeScalar;
// const splitAny = std.mem.splitAny;
// const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
// const indexOf = std.mem.indexOfScalar;
// const indexOfAny = std.mem.indexOfAny;
// const indexOfStr = std.mem.indexOfPosLinear;
// const lastIndexOf = std.mem.lastIndexOfScalar;
// const lastIndexOfAny = std.mem.lastIndexOfAny;
// const lastIndexOfStr = std.mem.lastIndexOfLinear;
// const trim = std.mem.trim;
// const sliceMin = std.mem.min;
// const sliceMax = std.mem.max;

// const parseInt = std.fmt.parseInt;
// const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
// const assert = std.debug.assert;

// const sort = std.sort.block;
// const asc = std.sort.asc;
// const desc = std.sort.desc;

const data = @embedFile("data/day17.txt");
const data_test = @embedFile("data/day17.test.txt");

const delta = [_]i32{ -1, 0, 1 };

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var cubes = try parseInput(input, false);
    defer cubes.deinit();

    var next = Map([4]i32, u8).init(gpa);
    defer next.deinit();

    const cycles: u8 = 6;
    for (0..cycles) |_| {
        var cubes_it = cubes.iterator();
        while (cubes_it.next()) |entry| {
            var active_neighbors = entry.value_ptr.*;
            var is_active = active_neighbors & (1 << 7) != 0;
            active_neighbors &= ~(@as(u8, 1) << 7);
            if (is_active) {
                is_active = active_neighbors == 2 or active_neighbors == 3;
            } else {
                is_active = active_neighbors == 3;
            }

            if (!is_active)
                continue;

            try next.put(entry.key_ptr.*, (1 << 7) | (next.get(entry.key_ptr.*) orelse 0));
            const x, const y, const z, _ = entry.key_ptr.*;
            for (delta) |dz| {
                for (delta) |dy| {
                    for (delta) |dx| {
                        if (dx == 0 and dy == 0 and dz == 0)
                            continue;

                        const neighbor = .{ x + dx, y + dy, z + dz, 0 };
                        try next.put(neighbor, 1 + (next.get(neighbor) orelse 0));
                    }
                }
            }
        }

        cubes = try next.clone();
        next.clearRetainingCapacity();
    }
    return activeCubes(cubes);
}

fn partTwo(input: []const u8) !u32 {
    var cubes = try parseInput(input, true);
    defer cubes.deinit();

    var next = Map([4]i32, u8).init(gpa);
    defer next.deinit();

    const cycles: u8 = 6;
    for (0..cycles) |_| {
        var cubes_it = cubes.iterator();
        while (cubes_it.next()) |entry| {
            var active_neighbors = entry.value_ptr.*;
            var is_active = active_neighbors & (1 << 7) != 0;
            active_neighbors &= ~(@as(u8, 1) << 7);
            if (is_active) {
                is_active = active_neighbors == 2 or active_neighbors == 3;
            } else {
                is_active = active_neighbors == 3;
            }

            if (!is_active)
                continue;

            try next.put(entry.key_ptr.*, (1 << 7) | (next.get(entry.key_ptr.*) orelse 0));
            const x, const y, const z, const w = entry.key_ptr.*;
            for (delta) |dw| {
                for (delta) |dz| {
                    for (delta) |dy| {
                        for (delta) |dx| {
                            if (dx == 0 and dy == 0 and dz == 0 and dw == 0)
                                continue;

                            const neighbor = .{ x + dx, y + dy, z + dz, w + dw };
                            try next.put(neighbor, 1 + (next.get(neighbor) orelse 0));
                        }
                    }
                }
            }
        }

        cubes = try next.clone();
        next.clearRetainingCapacity();
    }
    return activeCubes(cubes);
}

fn activeCubes(cubes: Map([4]i32, u8)) u32 {
    var active_count: u32 = 0;
    var cubes_it = cubes.valueIterator();
    while (cubes_it.next()) |active_neighbors| {
        const is_active = active_neighbors.* & (1 << 7) != 0;
        if (is_active)
            active_count += 1;
    }
    return active_count;
}

fn parseInput(input: []const u8, p2: bool) !Map([4]i32, u8) {
    var cubes = Map([4]i32, u8).init(gpa);
    var rows = splitSca(u8, input, '\n');
    var y: i32 = 0;
    while (rows.next()) |row| : (y += 1) {
        var x: i32 = 0;
        while (x < row.len) : (x += 1) {
            const c = row[@intCast(x)];
            if (c != '#')
                continue;

            const current = .{ x, y, 0, 0 };
            try cubes.put(current, (1 << 7) | (cubes.get(current) orelse 0));

            for (delta) |dw| {
                for (delta) |dz| {
                    for (delta) |dy| {
                        for (delta) |dx| {
                            if ((dx == 0 and dy == 0 and dz == 0 and dw == 0) or (!p2 and dw != 0))
                                continue;

                            const neighbor = .{ x + dx, y + dy, dz, dw };
                            try cubes.put(neighbor, 1 + (cubes.get(neighbor) orelse 0));
                        }
                    }
                }
            }
        }
    }
    return cubes;
}
