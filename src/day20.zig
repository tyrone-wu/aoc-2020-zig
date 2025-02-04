const std = @import("std");
const util = @import("util.zig");

const Map = std.AutoHashMap;
const List = std.ArrayList;
const Queue = std.fifo.LinearFifo;

const gpa = util.gpa;

const tokenizeSeq = std.mem.tokenizeSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day20.txt");
const data_test = @embedFile("data/day20.test.txt");

const Tile = struct {
    id: u16,
    image: [10][10]bool,
    connected: [4]u16,

    fn new(input: []const u8) !struct { u16, Tile } {
        const i_whitespace = indexOf(u8, input, ' ').?;
        const i_colon = indexOf(u8, input, ':').?;
        const id = try parseInt(u16, input[i_whitespace + 1 .. i_colon], 10);

        var image: [10][10]bool = undefined;
        var lines = splitSca(u8, input[i_colon + 2 ..], '\n');
        var y: usize = 0;
        while (lines.next()) |line| : (y += 1) {
            for (line, 0..) |c, x| {
                image[y][x] = c == '#';
            }
        }

        return .{
            id, Tile{
                .id = id,
                .image = image,
                .connected = .{ 0, 0, 0, 0 },
            },
        };
    }

    fn debug(self: Tile, with_id: bool) void {
        if (with_id)
            print("Tile {d}:\n", .{self.id});

        for (0..10) |y| {
            for (0..10) |x| {
                const c: u8 = if (self.image[y][x]) '#' else '.';
                print("{c}", .{c});
            }
            print("\n", .{});
        }
    }

    fn borders(self: Tile, invert: bool) [4]u16 {
        var borders_int = [4]u16{ 0, 0, 0, 0 };
        for (0..10) |i| {
            const t = if (invert) 9 - i else i;
            borders_int[0] = (borders_int[0] << 1) | @intFromBool(self.image[0][t]);
            borders_int[1] = (borders_int[1] << 1) | @intFromBool(self.image[t][9]);
            borders_int[2] = (borders_int[2] << 1) | @intFromBool(self.image[9][t]);
            borders_int[3] = (borders_int[3] << 1) | @intFromBool(self.image[t][0]);
        }
        return borders_int;
    }

    fn allBorders(self: Tile) [8]u16 {
        var borders_int = [8]u16{ 0, 0, 0, 0, 0, 0, 0, 0 };
        for (self.borders(false), 0..) |b, i| {
            borders_int[i] = b;
        }
        for (self.borders(true), 4..) |b, i| {
            borders_int[i] = b;
        }
        return borders_int;
    }

    fn connectedCount(self: Tile) u8 {
        var count: u8 = 0;
        for (self.connected) |id| {
            if (id != 0)
                count += 1;
        }
        return count;
    }

    fn isConnected(self: Tile, other: Tile) bool {
        for (self.connected) |id| {
            if (id == other.id)
                return true;
        }
        return false;
    }

    fn connect(self: *Tile, other: Tile) !void {
        if (self.connectedCount() >= 4)
            return error.ConnectionFull;
        if (self.id == other.id)
            return error.NoSelfConnect;

        for (self.connected, 0..) |id, i| {
            if (id == other.id)
                return error.AlreadyConnected;

            if (id == 0) {
                self.connected[i] = other.id;
                break;
            }
        }
    }

    fn rotateCw(self: *Tile) void {
        for (0..5) |layer| {
            const s = layer;
            const e = 9 - layer;
            for (s..e) |i| {
                const offset = i - s;
                const tmp = self.image[s][i];

                self.image[s][i] = self.image[e - offset][s];
                self.image[e - offset][s] = self.image[e][e - offset];
                self.image[e][e - offset] = self.image[i][e];
                self.image[i][e] = tmp;
            }
        }
    }

    fn reflect(self: *Tile) void {
        for (0..5) |y| {
            const tmp = self.image[y];
            self.image[y] = self.image[9 - y];
            self.image[9 - y] = tmp;
        }
    }
};

const sea_monster =
    \\                  # 
    \\#    ##    ##    ###
    \\ #  #  #  #  #  #   
;

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u64 {
    var tiles = try parseInput(input);
    defer tiles.deinit();

    try connectTiles(&tiles);

    var checksum: u64 = 1;
    var tiles_it = tiles.valueIterator();
    while (tiles_it.next()) |tile| {
        if (tile.connectedCount() == 2)
            checksum *= tile.id;
    }
    return checksum;
}

fn partTwo(input: []const u8) !u64 {
    var tiles = try parseInput(input);
    defer tiles.deinit();

    try connectTiles(&tiles);

    var it = tiles.valueIterator();
    const id_start = it.next().?.id;

    var id_y: u16 = undefined;

    var queue: Queue(u16, .Dynamic) = Queue(u16, .Dynamic).init(gpa);
    defer queue.deinit();
    try queue.ensureTotalCapacity(tiles.count());
    try queue.writeItem(id_start);

    var seen = Map(u16, void).init(gpa);
    defer seen.deinit();
    try seen.ensureTotalCapacity(tiles.count());

    while (queue.readItem()) |id| {
        if (seen.contains(id))
            continue;
        try seen.put(id, {});

        const tile = tiles.getPtr(id).?;
        const borders = tile.borders(false);
        var aligned = [4]u16{ 0, 0, 0, 0 };

        const neighbors = tiles.get(id).?.connected;
        for (neighbors) |id_adj| {
            if (id_adj == 0)
                continue;

            const other = tiles.getPtr(id_adj).?;
            var is_aligned = false;
            for (borders, 0..) |side, i| {
                for (0..4) |_| {
                    const other_side = other.borders(false)[@rem(i + 2, 4)];
                    if (side == other_side) {
                        aligned[i] = other.id;
                        is_aligned = true;
                        break;
                    }
                    other.rotateCw();
                }
                if (is_aligned)
                    break;

                other.reflect();
                for (0..4) |_| {
                    const other_side = other.borders(false)[@rem(i + 2, 4)];
                    if (side == other_side) {
                        aligned[i] = id_adj;
                        is_aligned = true;
                        break;
                    }
                    other.rotateCw();
                }
                if (is_aligned)
                    break;
            }

            try queue.writeItem(id_adj);
        }

        tile.connected = aligned;
        if (tile.connected[0] == 0 and tile.connected[3] == 0)
            id_y = id;
    }

    var grid = Map([2]u8, void).init(gpa);
    defer grid.deinit();

    var x_max: u8 = 0;
    var y_max: u8 = 0;

    var y_block: u8 = 0;
    while (id_y != 0) : (y_block += 1) {
        var id_x = id_y;
        var x_block: u8 = 0;
        while (id_x != 0) : (x_block += 1) {
            const tile_x = tiles.get(id_x).?;

            for (tile_x.image[1..9], 0..) |row, y| {
                const y_grid: u8 = @intCast(@as(u8, @intCast(y)) + y_block * 8);
                y_max = @max(y_max, y_grid);
                for (row[1..9], 0..) |c, x| {
                    const x_grid: u8 = @intCast(@as(u8, @intCast(x)) + x_block * 8);
                    if (c) {
                        try grid.put(.{ x_grid, y_grid }, {});
                        x_max = @max(x_max, x_grid);
                    }
                }
            }

            id_x = tile_x.connected[1];
        }

        const tile_y = tiles.get(id_y).?;
        id_y = tile_y.connected[2];
    }

    var delta_monster = List([2]u8).init(gpa);
    defer delta_monster.deinit();

    var lines = splitSca(u8, sea_monster, '\n');
    var y: u8 = 0;
    while (lines.next()) |line| : (y += 1) {
        var x: u8 = 0;
        for (line) |c| {
            if (c == '#')
                try delta_monster.append(.{ x, y });
            x += 1;
        }
    }

    var monsters_found: u64 = 0;
    for (0..4) |_| {
        monsters_found += findSeaMonster(grid, delta_monster.items);
        try rotateGrid(&grid, x_max);
    }
    try reflectGrid(&grid, y_max);
    for (0..4) |_| {
        monsters_found += findSeaMonster(grid, delta_monster.items);
        try rotateGrid(&grid, x_max);
    }

    return grid.count() - monsters_found * delta_monster.items.len;
}

fn findSeaMonster(grid: Map([2]u8, void), monster: []const [2]u8) u32 {
    var found: u32 = 0;
    var it = grid.keyIterator();
    while (it.next()) |pos| {
        const x = pos.*[0];
        const y = pos.*[1] -% 1;

        var matches = true;
        for (monster) |delta| {
            const dx, const dy = delta;
            if (!grid.contains(.{ x + dx, y + dy })) {
                matches = false;
                break;
            }
        }

        if (matches)
            found += 1;
    }
    return found;
}

fn rotateGrid(grid: *Map([2]u8, void), x_max: u8) !void {
    var original = try grid.clone();
    defer original.deinit();
    grid.clearRetainingCapacity();

    var it = original.keyIterator();
    while (it.next()) |pos| {
        const x, const y = pos.*;
        try grid.put(.{ y, x_max - x }, {});
    }
}

fn reflectGrid(grid: *Map([2]u8, void), y_max: u8) !void {
    var original = try grid.clone();
    defer original.deinit();
    grid.clearRetainingCapacity();

    var it = original.keyIterator();
    while (it.next()) |pos| {
        const x, const y = pos.*;
        try grid.put(.{ x, y_max - y }, {});
    }
}

fn debugGrid(grid: Map([2]u8, void), x_max: u8, y_max: u8) void {
    var y: u8 = 0;
    while (y <= y_max) : (y += 1) {
        var x: u8 = 0;
        while (x <= x_max) : (x += 1) {
            const c: u8 = if (grid.contains(.{ x, y })) '#' else '.';
            print("{c}", .{c});
        }
        print("\n", .{});
    }
}

fn connectTiles(tiles: *Map(u16, Tile)) !void {
    var tiles_it = tiles.valueIterator();
    while (tiles_it.next()) |tile| {
        if (tile.connectedCount() == 4)
            continue;

        const borders = tile.allBorders();
        var others_it = tiles.valueIterator();
        while (others_it.next()) |other| {
            if (tile.id == other.id or other.connectedCount() == 4 or tile.isConnected(other.*))
                continue;

            const other_borders = other.allBorders();
            var connected = false;
            for (borders) |border| {
                for (other_borders) |other_border| {
                    if (border == other_border) {
                        try tile.connect(other.*);
                        try other.connect(tile.*);
                        connected = true;
                        break;
                    }
                }
                if (connected)
                    break;
            }
        }
    }
}

fn parseInput(input: []const u8) !Map(u16, Tile) {
    var tiles_it = tokenizeSeq(u8, input, "\n\n");
    var tiles = Map(u16, Tile).init(gpa);
    while (tiles_it.next()) |tile_str| {
        const id, const tile = try Tile.new(tile_str);
        try tiles.put(id, tile);
    }
    return tiles;
}
