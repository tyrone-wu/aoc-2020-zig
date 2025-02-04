const std = @import("std");

const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const contains = std.mem.containsAtLeast;
const equals = std.mem.eql;

const data = @embedFile("data/day04.txt");
const data_test_p1 = @embedFile("data/day04.test.p1.txt");
const data_test_p2 = @embedFile("data/day04.test.p2.txt");

const fields = [_][]const u8{ "byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid", "cid" };
const eye_colors = [_][]const u8{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };

pub fn main() !void {
    const p1_test = try partOne(data_test_p1);
    const p2_test = try partTwo(data_test_p2);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var total_valid: u32 = 0;
    var passports = tokenizeSeq(u8, input, "\n\n");
    while (passports.next()) |passport| {
        if (try isValid(passport, false))
            total_valid += 1;
    }
    return total_valid;
}

fn partTwo(input: []const u8) !u32 {
    var total_valid: u32 = 0;
    var passports = tokenizeSeq(u8, input, "\n\n");
    while (passports.next()) |passport| {
        if (try isValid(passport, true))
            total_valid += 1;
    }
    return total_valid;
}

fn isValid(passport: []const u8, p2: bool) !bool {
    var valid: u32 = 0;
    if (!p2) {
        var has_cid = false;
        for (fields, 0..) |field, i| {
            if (contains(u8, passport, 1, field)) {
                valid += 1;
                if (i == fields.len - 1)
                    has_cid = true;
            }
        }
        return valid == 8 or (valid == 7 and !has_cid);
    } else {
        var tokens = tokenizeAny(u8, passport, ": \n");
        while (tokens.next()) |field| {
            if (equals(u8, field, "byr")) {
                const birth_year = try parseInt(u16, tokens.next().?, 10);
                if (1920 <= birth_year and birth_year <= 2002)
                    valid += 1;
            } else if (equals(u8, field, "iyr")) {
                const issue_year = try parseInt(u16, tokens.next().?, 10);
                if (2010 <= issue_year and issue_year <= 2020)
                    valid += 1;
            } else if (equals(u8, field, "eyr")) {
                const expire_year = try parseInt(u16, tokens.next().?, 10);
                if (2020 <= expire_year and expire_year <= 2030)
                    valid += 1;
            } else if (equals(u8, field, "hgt")) {
                const height_str = tokens.next().?;
                const height = parseInt(u16, height_str[0 .. height_str.len - 2], 10) catch continue;
                const units = height_str[height_str.len - 2 ..];
                if (equals(u8, units, "cm") and (150 <= height and height <= 193)) {
                    valid += 1;
                } else if (equals(u8, units, "in") and (59 <= height and height <= 76)) {
                    valid += 1;
                }
            } else if (equals(u8, field, "hcl")) {
                const hair_color = tokens.next().?;
                if (hair_color.len == 7 and hair_color[0] == '#') {
                    valid += 1;
                    for (hair_color[1..]) |c| {
                        switch (c) {
                            '0'...'9', 'a'...'f' => {},
                            else => {
                                valid -= 1;
                                break;
                            },
                        }
                    }
                }
            } else if (equals(u8, field, "ecl")) {
                const eye_color = tokens.next().?;
                for (eye_colors) |color| {
                    if (equals(u8, eye_color, color)) {
                        valid += 1;
                        break;
                    }
                }
            } else if (equals(u8, field, "pid")) {
                const passport_id = tokens.next().?;
                if (passport_id.len == 9) {
                    valid += 1;
                    for (passport_id) |c| {
                        switch (c) {
                            '0'...'9' => {},
                            else => {
                                valid -= 1;
                                break;
                            },
                        }
                    }
                }
            }
        }
        return valid == 7;
    }
}
