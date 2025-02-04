const std = @import("std");

const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const print = std.debug.print;

const data = @embedFile("data/day06.txt");
const data_test = @embedFile("data/day06.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var groups = tokenizeSeq(u8, input, "\n\n");
    var yes_total: u32 = 0;

    while (groups.next()) |answers| {
        var group_ans: u32 = 0;
        for (answers) |c| {
            if (c == '\n')
                continue;
            group_ans |= @as(u32, 1) << @truncate(c - 'a');
        }
        yes_total += @popCount(group_ans);
    }
    return yes_total;
}

fn partTwo(input: []const u8) !u32 {
    var groups = tokenizeSeq(u8, input, "\n\n");
    var yes_total: u32 = 0;

    while (groups.next()) |answers| {
        var group_ans: u32 = (1 << 26) - 1;

        var answer = tokenizeSca(u8, answers, '\n');
        while (answer.next()) |ans| {
            var yes: u32 = 0;
            for (ans) |c|
                yes |= @as(u32, 1) << @truncate(c - 'a');
            group_ans &= yes;
        }
        yes_total += @popCount(group_ans);
    }
    return yes_total;
}
