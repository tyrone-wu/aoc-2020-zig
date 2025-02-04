const std = @import("std");

const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day25.txt");
const data_test = @embedFile("data/day25.test.txt");

pub fn main() !void {
    const p1_test = try partOne(data_test);
    print("Test:\n  part 1: {d}\n\n", .{p1_test});

    const p1 = try partOne(data);
    print("Puzzle:\n  part 1: {d}\n", .{p1});
}

fn partOne(input: []const u8) !u64 {
    var tokens = splitSca(u8, input, '\n');
    const card_pub = try parseInt(u64, tokens.next().?, 10);
    const door_pub = try parseInt(u64, tokens.next().?, 10);

    const card_loop_size = findLoopSize(card_pub);
    const door_loop_size = findLoopSize(door_pub);

    const card_key = encryptionKey(card_pub, door_loop_size);
    const door_key = encryptionKey(door_pub, card_loop_size);
    if (card_key != door_key)
        return error.KeysNotEqual;

    return door_key;
}

fn encryptionKey(subject_number: u64, loop_size: u64) u64 {
    var value: u64 = 1;
    for (0..loop_size) |_| {
        value *= subject_number;
        value = @rem(value, 20201227);
    }
    return value;
}

fn findLoopSize(public_key: u64) u64 {
    const subject_number: u64 = 7;
    var loop_size: u64 = 0;
    var value: u64 = 1;
    while (value != public_key) : (loop_size += 1) {
        value *= subject_number;
        value = @rem(value, 20201227);
    }
    return loop_size;
}
