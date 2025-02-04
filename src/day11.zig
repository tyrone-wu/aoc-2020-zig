const std = @import("std");
const util = @import("util.zig");

const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const print = std.debug.print;

const data = @embedFile("data/day11.txt");
const data_test = @embedFile("data/day11.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u16 {
    var seats = try parseInput(input);
    defer seats.deinit();
    try converge(&seats, false);
    return occupiedSeats(seats);
}

fn partTwo(input: []const u8) !u16 {
    var seats = try parseInput(input);
    defer seats.deinit();
    try converge(&seats, true);
    return occupiedSeats(seats);
}

fn converge(seats: *Map(i16, bool), p2: bool) !void {
    var bounds = [_]i16{ 0, 0 };
    var it = seats.keyIterator();
    while (it.next()) |seat| {
        const x, const y = decode(seat.*);
        bounds[0] = @max(bounds[0], x);
        bounds[1] = @max(bounds[1], y);
    }

    var next = try seats.clone();
    defer next.deinit();

    while (true) {
        var seat_it = seats.keyIterator();
        while (seat_it.next()) |seat| {
            const occupied = seats.get(seat.*) orelse continue;
            const x, const y = decode(seat.*);

            const adj_occ = adjacentOccupied(seats.*, bounds, x, y, p2);
            if (!p2) {
                if (occupied and adj_occ >= 4) {
                    try next.put(seat.*, false);
                } else if (!occupied and adj_occ == 0) {
                    try next.put(seat.*, true);
                }
            } else {
                if (occupied and adj_occ >= 5) {
                    try next.put(seat.*, false);
                } else if (!occupied and adj_occ == 0) {
                    try next.put(seat.*, true);
                }
            }
        }
        if (isStabilized(seats.*, next))
            break;
        seats.* = try next.clone();
    }
}

const delta_adj = [_][2]i16{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
    .{ -1, -1 },
    .{ 1, -1 },
    .{ -1, 1 },
    .{ 1, 1 },
};

fn adjacentOccupied(seats: Map(i16, bool), bounds: [2]i16, x: i16, y: i16, p2: bool) u8 {
    var occupied_count: u8 = 0;
    const x_max, const y_max = bounds;
    for (delta_adj) |delta| {
        const dx, const dy = delta;
        var x_c = x;
        var y_c = y;

        while ((1 <= x_c and x_c <= x_max) and (1 <= y_c and y_c <= y_max)) {
            x_c += dx;
            y_c += dy;
            const occupied = seats.get(encode(x_c, y_c));
            if (occupied != null) {
                if (occupied.?)
                    occupied_count += 1;
                break;
            }
            if (!p2)
                break;
        }
    }
    return occupied_count;
}

fn occupiedSeats(seats: Map(i16, bool)) u16 {
    var total_occupied: u16 = 0;
    var occupied_it = seats.valueIterator();
    while (occupied_it.next()) |occupied| {
        if (occupied.*)
            total_occupied += 1;
    }
    return total_occupied;
}

fn isStabilized(seats: Map(i16, bool), next: Map(i16, bool)) bool {
    var seats_it = seats.iterator();
    while (seats_it.next()) |entry| {
        const coord = entry.key_ptr.*;
        const occupied = entry.value_ptr.*;
        if (next.get(coord).? != occupied)
            return false;
    }
    return true;
}

fn decode(seat: i16) [2]i16 {
    const x = seat >> 8;
    const y = seat & ((1 << 8) - 1);
    return .{ x, y };
}

fn encode(x: i16, y: i16) i16 {
    return (x << 8) | y;
}

fn parseInput(input: []const u8) !Map(i16, bool) {
    var seats = Map(i16, bool).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    var y: i16 = 1;
    while (lines.next()) |line| : (y += 1) {
        var x: i16 = 1;
        for (line) |c| {
            if (c == 'L')
                try seats.put(encode(x, y), false);
            x += 1;
        }
    }
    return seats;
}
