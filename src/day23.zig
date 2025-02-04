const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const print = std.debug.print;

const data = @embedFile("data/day23.txt");
const data_test = @embedFile("data/day23.test.txt");

const Cup = struct {
    prev: usize,
    next: usize,

    fn new(prev: usize, next: usize) Cup {
        return Cup{ .prev = prev, .next = next };
    }
};

const Cups = struct {
    data: List(Cup),
    i: usize,

    fn new(input: []const u8, p2: bool) !Cups {
        const size: usize = if (!p2) 9 else 1000000;

        var cups = List(Cup).init(gpa);
        try cups.ensureUnusedCapacity(size + 1);
        for (0..size) |_| {
            try cups.append(undefined);
        }

        const cups_str = input[0 .. input.len - 1];
        for (0..cups_str.len) |i| {
            const value = cups_str[i] - '1';
            const prev = cups_str[@rem(i + cups_str.len - 1, cups_str.len)] - '1';
            const next = cups_str[@rem(i + 1, cups_str.len)] - '1';
            cups.items[value] = Cup.new(prev, next);
        }

        if (p2) {
            const head = cups_str[0] - '1';
            cups.items[head].prev = size - 1;
            cups.items[cups_str[8] - '1'].next = 9;

            for (9..size) |value| {
                const prev = value - 1;
                const next = if (value + 1 != size) value + 1 else head;
                cups.items[value] = Cup.new(prev, next);
            }
        }

        return Cups{ .data = cups, .i = cups_str[0] - '1' };
    }

    fn deinit(self: *Cups) void {
        self.data.deinit();
    }

    fn at(self: *Cups, i: usize) *Cup {
        return &self.data.items[i];
    }

    fn debug(self: Cups) void {
        print("cups:", .{});
        var i = self.i;
        for (0..self.data.items.len) |_| {
            if (i == self.i) {
                print(" ({d})", .{i + 1});
            } else {
                print(" {d}", .{i + 1});
            }
            i = self.data.items[i].next;
        }
        print("\n", .{});
    }

    fn move(self: *Cups, verbose: bool) void {
        if (verbose)
            self.debug();

        var pick_up: [3]usize = undefined;
        var j = self.at(self.i).next;
        for (0..3) |i| {
            pick_up[i] = j;
            j = self.at(j).next;
        }

        self.at(self.i).next = self.at(pick_up[2]).next;
        self.at(self.at(pick_up[2]).next).prev = self.i;

        const len = self.data.items.len;
        var destination = @rem(self.i + len - 1, len);
        while (destination == pick_up[0] or destination == pick_up[1] or destination == pick_up[2]) {
            destination = @rem(destination + len - 1, len);
        }
        const cup_dst = self.at(destination);

        self.at(cup_dst.next).prev = pick_up[2];
        self.at(pick_up[2]).next = cup_dst.next;

        cup_dst.next = pick_up[0];
        self.at(pick_up[0]).prev = destination;

        self.i = self.at(self.i).next;

        if (verbose) {
            print("pick up ", .{});
            for (pick_up) |cup| {
                print(" {d}", .{cup + 1});
            }
            print("\ndestination: {d}\n", .{destination + 1});
        }
    }
};

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u64 {
    var cups = try Cups.new(input, false);
    defer cups.deinit();

    const moves: u8 = 100;
    for (0..moves) |_| {
        cups.move(false);
        // print("\n", .{});
    }
    // cups.debug();

    var labels: u64 = 0;
    var i: usize = cups.at(0).next;
    for (0..8) |_| {
        labels = labels * 10 + i + 1;
        i = cups.at(i).next;
    }
    return labels;
}

fn partTwo(input: []const u8) !u64 {
    var cups = try Cups.new(input, true);
    defer cups.deinit();

    const moves: u32 = 10000000;
    for (0..moves) |_| {
        cups.move(false);
    }

    var checksum: u64 = 1;
    var i = cups.at(0).next;
    for (0..2) |_| {
        checksum *= i + 1;
        i = cups.at(i).next;
    }
    return checksum;
}
