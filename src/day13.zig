const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const divCeil = std.math.divCeil;
const maxInt = std.math.maxInt;

const data = @embedFile("data/day13.txt");
const data_test = @embedFile("data/day13.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u64 {
    const timestamp, const bus_ids = try parseInput(input);
    defer bus_ids.deinit();

    var bus_id: u64 = 0;
    var wait_time: u64 = maxInt(u64);
    for (bus_ids.items) |id| {
        if (id == 0)
            continue;

        const factor = try divCeil(u64, timestamp, id);
        const bus_time = factor * id;
        if (bus_time < wait_time) {
            wait_time = bus_time;
            bus_id = id;
        }
    }
    return (wait_time - timestamp) * bus_id;
}

fn partTwo(input: []const u8) !u64 {
    _, const bus_ids = try parseInput(input);
    defer bus_ids.deinit();

    var minute: u64 = 0;
    var period: u64 = 1;
    for (bus_ids.items, 0..) |id, offset| {
        if (id == 0)
            continue;

        while (@rem(minute + offset, id) != 0) {
            minute += period;
        }
        period *= id;
    }
    return minute;
}

fn parseInput(input: []const u8) !struct { u64, List(u64) } {
    var lines = splitSca(u8, input, '\n');
    const timestamp = try parseInt(u64, lines.next().?, 10);

    var bus_ids = List(u64).init(gpa);
    var ids_it = splitSca(u8, lines.next().?, ',');
    while (ids_it.next()) |id| {
        try bus_ids.append(parseInt(u64, id, 10) catch 0);
    }
    return .{ timestamp, bus_ids };
}
