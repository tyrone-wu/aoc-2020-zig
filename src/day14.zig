const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.indexOfScalar;
const lastIndexOf = std.mem.lastIndexOfScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day14.txt");
const data_test_p1 = @embedFile("data/day14.test.p1.txt");
const data_test_p2 = @embedFile("data/day14.test.p2.txt");

const Instruction = union(enum) {
    mask: [36]?bool,
    mem: [2]u64,

    fn new(input: []const u8) !Instruction {
        if (input[1] == 'e') {
            var nums = tokenizeAny(u8, input, "mem[] =");
            const mem = [2]u64{
                try parseInt(u64, nums.next().?, 10),
                try parseInt(u64, nums.next().?, 10),
            };
            return Instruction{ .mem = mem };
        } else {
            var mask: [36]?bool = undefined;
            for (&mask) |*b| {
                b.* = null;
            }

            for (input[lastIndexOf(u8, input, ' ').? + 1 ..], 0..) |c, i| {
                if (c == '1') {
                    mask[i] = true;
                } else if (c == '0') {
                    mask[i] = false;
                }
            }
            return Instruction{ .mask = mask };
        }
    }
};

pub fn main() !void {
    const p1_test = try partOne(data_test_p1);
    const p2_test = try partTwo(data_test_p2);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u64 {
    const insns = try parseInput(input);
    defer insns.deinit();
    return try decode(insns.items, false);
}

fn partTwo(input: []const u8) !u64 {
    const insns = try parseInput(input);
    defer insns.deinit();
    return try decode(insns.items, true);
}

fn decode(insns: []const Instruction, p2: bool) !u64 {
    var memory = Map(u64, u64).init(gpa);
    defer memory.deinit();

    var i_mask: usize = 0;
    for (insns[1..], 1..) |insn, i| {
        switch (insn) {
            .mask => i_mask = i,
            .mem => {
                try writeToMemory(&memory, &insns[i_mask].mask, insn.mem, p2);
            },
        }
    }
    return sumMemory(memory);
}

fn writeToMemory(memory: *Map(u64, u64), mask: []const ?bool, mem: [2]u64, p2: bool) !void {
    const addr, var value = mem;
    if (!p2) {
        for (mask, 0..) |m, i| {
            const b = m orelse continue;
            const target: u64 = @as(u64, 1) << @truncate(35 - i);
            if (b) {
                value |= target;
            } else {
                value &= ~target;
            }
        }
        try memory.put(addr, value);
    } else {
        var encoded_addr: [36]?bool = undefined;
        for (mask, 0..) |m_opt, i| {
            const target: u64 = @as(u64, 1) << @truncate(35 - i);
            encoded_addr[i] = m_opt;
            if (m_opt) |m| {
                encoded_addr[i] = switch (m) {
                    false => addr & target != 0,
                    true => true,
                };
            }
        }

        var addrs = List(u64).init(gpa);
        defer addrs.deinit();

        try dfs(&addrs, 0, &encoded_addr);

        for (addrs.items) |addr_w| {
            try memory.put(addr_w, value);
        }
    }
}

fn dfs(addrs: *List(u64), addr: u64, encoded_addr: []const ?bool) !void {
    if (encoded_addr.len == 0) {
        try addrs.append(addr);
        return;
    }

    if (encoded_addr[0]) |b| {
        try dfs(addrs, (addr << 1) | @intFromBool(b), encoded_addr[1..]);
    } else {
        try dfs(addrs, addr << 1, encoded_addr[1..]);
        try dfs(addrs, (addr << 1) | 1, encoded_addr[1..]);
    }
}

fn sumMemory(memory: Map(u64, u64)) u64 {
    var sum: u64 = 0;
    var value_it = memory.valueIterator();
    while (value_it.next()) |value| {
        sum += value.*;
    }
    return sum;
}

fn parseInput(input: []const u8) !List(Instruction) {
    var insns = List(Instruction).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        try insns.append(try Instruction.new(line));
    }
    return insns;
}
