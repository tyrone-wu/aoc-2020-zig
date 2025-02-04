const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day02.txt");
const data_test = @embedFile("data/day02.test.txt");

const PasswordPolicy = struct {
    min: u8,
    max: u8,
    letter: u8,
    password: []const u8,
};

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u16 {
    const password_policies = try parseInput(input);
    defer password_policies.deinit();

    var valid: u16 = 0;
    for (password_policies.items) |policy| {
        var count: u8 = 0;
        for (policy.password) |c| {
            if (policy.letter == c)
                count += 1;
        }
        if ((policy.min <= count) and (count <= policy.max))
            valid += 1;
    }
    return valid;
}

fn partTwo(input: []const u8) !u16 {
    const password_policies = try parseInput(input);
    defer password_policies.deinit();

    var valid: u16 = 0;
    for (password_policies.items) |policy| {
        const password = &policy.password;
        const pass_len = password.len;
        const target = policy.letter;
        if ((policy.min <= pass_len and password.*[policy.min - 1] == target) != (policy.max <= pass_len and password.*[policy.max - 1] == target))
            valid += 1;
    }
    return valid;
}

fn parseInput(input: []const u8) !List(PasswordPolicy) {
    var password_policies = List(PasswordPolicy).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        var tokens = tokenizeAny(u8, line, "- :");
        const policy = PasswordPolicy{
            .min = try parseInt(u8, tokens.next().?, 10),
            .max = try parseInt(u8, tokens.next().?, 10),
            .letter = tokens.next().?[0],
            .password = tokens.next().?,
        };
        try password_policies.append(policy);
    }
    return password_policies;
}
