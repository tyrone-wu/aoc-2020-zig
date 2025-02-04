const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;
const Queue = std.fifo.LinearFifo;

const gpa = util.gpa;

const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.indexOfScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day22.txt");
const data_test = @embedFile("data/day22.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    print("Test:\n  part 1: {d}\n  part 2: {d}\n\n", .{ p1_test, p2_test });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    print("Puzzle:\n  part 1: {d}\n  part 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    var deck_one, var deck_two = try parseInput(input);
    defer {
        deck_one.deinit();
        deck_two.deinit();
    }
    try deck_one.ensureUnusedCapacity(deck_two.count);
    try deck_two.ensureUnusedCapacity(deck_one.count);

    while (deck_one.count != 0 and deck_two.count != 0) {
        const card_one = deck_one.readItem().?;
        const card_two = deck_two.readItem().?;
        if (card_one > card_two) {
            try deck_one.writeItem(card_one);
            try deck_one.writeItem(card_two);
        } else {
            try deck_two.writeItem(card_two);
            try deck_two.writeItem(card_one);
        }
    }

    return if (deck_one.count > 0) deckScore(&deck_one) else deckScore(&deck_two);
}

fn partTwo(input: []const u8) !u32 {
    var deck_one, var deck_two = try parseInput(input);
    defer {
        deck_one.deinit();
        deck_two.deinit();
    }
    try deck_one.ensureUnusedCapacity(deck_two.count);
    try deck_two.ensureUnusedCapacity(deck_one.count);

    const scores = try recurseCombat(&deck_one, deck_one.count, &deck_two, deck_two.count);
    return if (scores[0] != 0) scores[0] else scores[1];
}

fn recurseCombat(deck_one: *Queue(u8, .Dynamic), draw_one: usize, deck_two: *Queue(u8, .Dynamic), draw_two: usize) ![2]u32 {
    deck_one.realign();
    deck_two.realign();

    var clone_one = Queue(u8, .Dynamic).init(gpa);
    defer clone_one.deinit();
    var clone_two = Queue(u8, .Dynamic).init(gpa);
    defer clone_two.deinit();

    const total_capacity = deck_one.count + deck_two.count;
    try clone_one.ensureUnusedCapacity(total_capacity);
    try clone_two.ensureUnusedCapacity(total_capacity);

    try clone_one.write(deck_one.readableSlice(0)[0..draw_one]);
    try clone_two.write(deck_two.readableSlice(0)[0..draw_two]);

    var seen = Map([2]u32, void).init(gpa);
    defer seen.deinit();

    while (clone_one.count != 0 and clone_two.count != 0) {
        const score_one = deckScore(&clone_one);
        const key = .{ score_one, deckScore(&clone_two) };
        if (seen.contains(key))
            return .{ score_one, 0 };
        try seen.put(key, {});

        const card_one = clone_one.readItem().?;
        const card_two = clone_two.readItem().?;

        const one_won = switch (clone_one.count >= card_one and clone_two.count >= card_two) {
            false => card_one > card_two,
            true => (try recurseCombat(&clone_one, card_one, &clone_two, card_two))[0] != 0,
        };
        if (one_won) {
            try clone_one.writeItem(card_one);
            try clone_one.writeItem(card_two);
        } else {
            try clone_two.writeItem(card_two);
            try clone_two.writeItem(card_one);
        }
    }

    if (clone_one.count > 0) {
        return .{ deckScore(&clone_one), 0 };
    } else {
        return .{ 0, deckScore(&clone_two) };
    }
}

fn deckScore(deck: *Queue(u8, .Dynamic)) u32 {
    deck.realign();
    const deck_slice = deck.readableSlice(0);
    var score: u64 = 0;
    for (deck_slice, 0..) |card, i| {
        score += card * (deck_slice.len - i);
    }
    return @intCast(score);
}

fn parseInput(input: []const u8) ![2]Queue(u8, .Dynamic) {
    var players_it = tokenizeSeq(u8, input, "\n\n");
    return .{
        try parseDeck(players_it.next().?),
        try parseDeck(players_it.next().?),
    };
}

fn parseDeck(input: []const u8) !Queue(u8, .Dynamic) {
    var deck = Queue(u8, .Dynamic).init(gpa);
    var lines = tokenizeSca(u8, input[indexOf(u8, input, '\n').? + 1 ..], '\n');
    while (lines.next()) |line| {
        try deck.writeItem(try parseInt(u8, line, 10));
    }
    return deck;
}
