const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;
const StaticStringMap = std.StaticStringMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const print = std.debug.print;

const data = @embedFile("data/day24.txt");
const data_test = @embedFile("data/day24.test.txt");

const deltas = StaticStringMap([3]i32).initComptime(.{
    .{ "e", .{ 0, 1, -1 } },
    .{ "se", .{ 1, 0, -1 } },
    .{ "sw", .{ 1, -1, 0 } },
    .{ "w", .{ 0, -1, 1 } },
    .{ "nw", .{ -1, 0, 1 } },
    .{ "ne", .{ -1, 1, 0 } },
});

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var tiles = try renovate(input);
    defer tiles.deinit();

    return blackTiles(tiles);
}

fn partTwo(input: []const u8) !u32 {
    var tiles = try renovate(input);
    defer tiles.deinit();

    var buffer = Map([3]i32, u8).init(gpa);
    defer buffer.deinit();

    const days: u8 = 100;
    for (0..days) |_| {
        buffer = try tiles.clone();
        // tiles.clearRetainingCapacity();

        var it = buffer.iterator();
        while (it.next()) |entry| {
            const pos = entry.key_ptr.*;
            var black_adj = entry.value_ptr.*;
            const black = (black_adj & (1 << 7)) != 0;
            black_adj = black_adj & ~(@as(u8, 1) << 7);

            if (black and (black_adj == 0 or black_adj > 2)) {
                try flipTile(&tiles, pos, false);
            } else if (!black and black_adj == 2) {
                try flipTile(&tiles, pos, true);
            }
        }
    }

    return blackTiles(tiles);
}

fn renovate(input: []const u8) !Map([3]i32, u8) {
    const renovation = try parseInput(input);
    defer {
        for (renovation.items) |*tile| {
            tile.deinit();
        }
        renovation.deinit();
    }

    var tiles = Map([3]i32, u8).init(gpa);
    for (renovation.items) |directions| {
        var x: i32 = 0;
        var y: i32 = 0;
        var z: i32 = 0;
        for (directions.items) |direction| {
            const dx, const dy, const dz = deltas.get(direction).?;
            x += dx;
            y += dy;
            z += dz;
        }

        const tile_pos = [3]i32{ x, y, z };
        const black = ((tiles.get(tile_pos) orelse 0) >> 7) == 0;
        try flipTile(&tiles, tile_pos, black);
    }
    return tiles;
}

fn flipTile(tiles: *Map([3]i32, u8), pos: [3]i32, black: bool) !void {
    try tiles.put(pos, (tiles.get(pos) orelse 0) ^ (1 << 7));

    const x, const y, const z = pos;
    for (deltas.values()) |delta| {
        const dx, const dy, const dz = delta;
        const adj_pos = .{ x + dx, y + dy, z + dz };
        const black_adj = switch (black) {
            false => (tiles.get(adj_pos) orelse 0) - 1,
            true => (tiles.get(adj_pos) orelse 0) + 1,
        };
        try tiles.put(adj_pos, black_adj);
    }
}

fn blackTiles(tiles: Map([3]i32, u8)) u32 {
    var black_tiles: u32 = 0;
    var tiles_it = tiles.valueIterator();
    while (tiles_it.next()) |tile| {
        if ((tile.* >> 7) == 1)
            black_tiles += 1;
    }
    return black_tiles;
}

fn parseInput(input: []const u8) !List(List([]const u8)) {
    var tiles = List(List([]const u8)).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        var directions = List([]const u8).init(gpa);
        var i: u16 = 0;
        while (i < line.len) {
            const j: u16 = if (line[i] == 'e' or line[i] == 'w') 1 else 2;
            try directions.append(line[i .. i + j]);
            i += j;
        }
        try tiles.append(directions);
    }
    return tiles;
}
