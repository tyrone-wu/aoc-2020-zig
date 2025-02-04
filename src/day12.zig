const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day12.txt");
const data_test = @embedFile("data/day12.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

const Action = enum(u8) {
    N = 0,
    E = 1,
    S = 2,
    W = 3,
    L,
    R,
    F,
};

const NavInsn = struct {
    action: Action,
    units: i16,

    fn new(input: []const u8) !NavInsn {
        const action = switch (input[0]) {
            'N' => Action.N,
            'E' => Action.E,
            'S' => Action.S,
            'W' => Action.W,
            'L' => Action.L,
            'R' => Action.R,
            'F' => Action.F,
            else => return error.InvalidAction,
        };
        const units = try parseInt(i16, input[1..], 10);

        return NavInsn{
            .action = action,
            .units = units,
        };
    }
};

const Ship = struct {
    x: i32,
    y: i32,
    direction: Action,

    fn new(x: i32, y: i32) Ship {
        return Ship{
            .x = x,
            .y = y,
            .direction = Action.E,
        };
    }

    fn move(self: *Ship, nav: NavInsn) void {
        switch (nav.action) {
            Action.N => self.y += nav.units,
            Action.E => self.x += nav.units,
            Action.S => self.y -= nav.units,
            Action.W => self.x -= nav.units,
            Action.L, Action.R => {
                const turns = @divFloor(nav.units, 90) * @as(i8, if (nav.action == Action.L) -1 else 1);
                self.direction = @enumFromInt(@mod(@intFromEnum(self.direction) + turns, 4));
            },
            Action.F => self.move(NavInsn{ .action = self.direction, .units = nav.units }),
        }
    }
};

fn partOne(input: []const u8) !u32 {
    var nav_insns = try parseInput(input);
    defer nav_insns.deinit();

    var ship = Ship.new(0, 0);
    for (nav_insns.items) |nav| {
        ship.move(nav);
    }
    return @abs(ship.x) + @abs(ship.y);
}

fn partTwo(input: []const u8) !u32 {
    var nav_insns = try parseInput(input);
    defer nav_insns.deinit();

    var ship = Ship.new(0, 0);
    var waypoint = Ship.new(10, 1);
    for (nav_insns.items) |nav| {
        moveP2(&ship, &waypoint, nav);
    }
    return @abs(ship.x) + @abs(ship.y);
}

fn moveP2(ship: *Ship, waypoint: *Ship, nav: NavInsn) void {
    switch (nav.action) {
        Action.N, Action.E, Action.S, Action.W => waypoint.move(nav),
        Action.L, Action.R => {
            const turns = @divFloor(nav.units, 90);
            for (0..@intCast(turns)) |_| {
                const tmp = waypoint.x;
                if (nav.action == Action.L) {
                    waypoint.x = -waypoint.y;
                    waypoint.y = tmp;
                } else {
                    waypoint.x = waypoint.y;
                    waypoint.y = -tmp;
                }
            }
        },
        Action.F => {
            const dx = waypoint.x * nav.units;
            const dy = waypoint.y * nav.units;
            ship.x += dx;
            ship.y += dy;
        },
    }
}

fn parseInput(input: []const u8) !List(NavInsn) {
    var nav_insns = List(NavInsn).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        try nav_insns.append(try NavInsn.new(line));
    }
    return nav_insns;
}
