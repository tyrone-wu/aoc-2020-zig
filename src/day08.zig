const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const equals = std.mem.eql;
const zeroes = std.mem.zeroes;

const data = @embedFile("data/day08.txt");
const data_test = @embedFile("data/day08.test.txt");

const Op = enum {
    acc,
    jmp,
    nop,
};

const Instruction = struct {
    op: Op,
    arg: i32,
};

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !i32 {
    const instructions = try parseInput(input);
    defer instructions.deinit();

    _, const accumulator = try runCode(instructions.items, 0);
    return accumulator;
}

fn partTwo(input: []const u8) !i32 {
    const instructions = try parseInput(input);
    defer instructions.deinit();

    for (instructions.items) |*insn| {
        if (insn.op == Op.acc)
            continue;

        const tmp_op = insn.op;
        insn.op = if (insn.op == Op.jmp) Op.nop else Op.jmp;
        const i, const accumulator = try runCode(instructions.items, 100);
        if (i >= instructions.items.len)
            return accumulator;
        insn.op = tmp_op;
    }

    return error.NoSolution;
}

fn runCode(instructions: []const Instruction, threshold: u8) !struct { i32, i32 } {
    var i: i32 = 0;
    var accumulator: i32 = 0;

    var insns_executed = List(u8).init(gpa);
    defer insns_executed.deinit();
    try insns_executed.ensureTotalCapacityPrecise(instructions.len);
    for (0..instructions.len) |_| {
        try insns_executed.append(0);
    }

    while (i < instructions.len) : (i += 1) {
        const idx: usize = @intCast(i);
        const insn = &instructions[idx];
        if (insns_executed.items[idx] > threshold)
            break;

        switch (insn.op) {
            Op.acc => accumulator += insn.arg,
            Op.jmp => i += insn.arg - 1,
            Op.nop => {},
        }
        insns_executed.items[idx] += 1;
    }
    return .{ i, accumulator };
}

fn parseInput(input: []const u8) !List(Instruction) {
    var instructions = List(Instruction).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |insn| {
        var split = splitSca(u8, insn, ' ');
        const op = std.meta.stringToEnum(Op, split.next().?) orelse return error.InvalidOp;
        const arg = try parseInt(i32, split.next().?, 10);
        try instructions.append(Instruction{ .op = op, .arg = arg });
    }
    return instructions;
}
