const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const Map = std.AutoHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day19.txt");
const data_test_p1 = @embedFile("data/day19.test.p1.txt");
const data_test_p2 = @embedFile("data/day19.test.p2.txt");

const Rule = union(enum) {
    char: u8,
    subrules: List(List(u8)),

    fn new(input: []const u8) !Rule {
        if (input[0] == '"') {
            return Rule{ .char = input[1] };
        } else {
            var subrules = List(List(u8)).init(gpa);
            var subrules_it = splitSeq(u8, input, " | ");
            while (subrules_it.next()) |subrule_str| {
                var subrule = List(u8).init(gpa);
                var nums_it = splitSca(u8, subrule_str, ' ');
                while (nums_it.next()) |num_str| {
                    try subrule.append(try parseInt(u8, num_str, 10));
                }
                try subrules.append(subrule);
            }

            return Rule{ .subrules = subrules };
        }
    }

    fn deinit(self: *Rule) void {
        switch (self.*) {
            .subrules => {
                for (self.subrules.items) |*r| {
                    r.deinit();
                }
                self.subrules.deinit();
            },
            else => {},
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

fn partOne(input: []const u8) !u16 {
    var rules, const messages = try parseInput(input);
    defer {
        var it = rules.valueIterator();
        while (it.next()) |rule| {
            rule.deinit();
        }
        rules.deinit();

        messages.deinit();
    }

    return try rulesMatched(rules, messages.items);
}

// ~15 sec
fn partTwo(input: []const u8) !u16 {
    var rules, const messages = try parseInput(input);
    defer {
        var it = rules.valueIterator();
        while (it.next()) |rule| {
            rule.deinit();
        }
        rules.deinit();

        messages.deinit();
    }

    try rules.put(8, try Rule.new("42 | 42 8"));
    try rules.put(11, try Rule.new("42 31 | 42 11 31"));

    return try rulesMatched(rules, messages.items);
}

fn rulesMatched(rules: Map(u8, Rule), messages: [][]const u8) !u16 {
    var matches: u16 = 0;
    for (messages) |msg| {
        const len_matched = try dfs(rules, 0, msg);
        defer len_matched.deinit();

        for (len_matched.items) |i| {
            if (i == msg.len) {
                matches += 1;
                // print("{s}\n", .{msg});
                break;
            }
        }
    }
    return matches;
}

fn dfs(rules: Map(u8, Rule), rule_num: u8, msg: []const u8) !List(usize) {
    var len_matched = List(usize).init(gpa);

    if (msg.len == 0)
        return len_matched;

    const rule = rules.get(rule_num).?;
    switch (rule) {
        .char => {
            if (rule.char == msg[0])
                try len_matched.append(1);
        },
        .subrules => {
            for (rule.subrules.items) |subrule| {
                var indicies = List(usize).init(gpa);
                defer indicies.deinit();
                try indicies.append(0);

                var next = List(usize).init(gpa);
                defer next.deinit();

                for (subrule.items) |num| {
                    for (indicies.items) |i| {
                        if (i > msg.len) {
                            continue;
                        }

                        const sub_matches = try dfs(rules, num, msg[i..]);
                        defer sub_matches.deinit();

                        for (sub_matches.items) |j| {
                            try next.append(i + j);
                        }
                    }

                    indicies.clearRetainingCapacity();
                    for (next.items) |i| {
                        try indicies.append(i);
                    }
                    next.clearRetainingCapacity();
                }

                for (indicies.items) |i| {
                    try len_matched.append(i);
                }
            }
        },
    }
    return len_matched;
}

fn parseInput(input: []const u8) !struct { Map(u8, Rule), List([]const u8) } {
    var sections = splitSeq(u8, input, "\n\n");

    var rules = Map(u8, Rule).init(gpa);
    var rules_it = tokenizeSca(u8, sections.next().?, '\n');
    while (rules_it.next()) |rule_str| {
        var split = splitSeq(u8, rule_str, ": ");

        const num = try parseInt(u8, split.next().?, 10);
        const rule = try Rule.new(split.next().?);

        try rules.put(num, rule);
    }

    var messages = List([]const u8).init(gpa);
    var msgs_it = tokenizeSca(u8, sections.next().?, '\n');
    while (msgs_it.next()) |msg_str| {
        try messages.append(msg_str);
    }

    return .{ rules, messages };
}
