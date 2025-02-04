const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;

const gpa = util.gpa;

const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitSeq = std.mem.splitSequence;
const indexOf = std.mem.indexOfScalar;
const indexOfStr = std.mem.indexOfPosLinear;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const startsWith = std.mem.startsWith;

const data = @embedFile("data/day16.txt");
const data_test_p1 = @embedFile("data/day16.test.p1.txt");
const data_test_p2 = @embedFile("data/day16.test.p2.txt");

const Field = struct {
    name: []const u8,
    valid_ranges: [2][2]u16,

    fn new(input: []const u8) !Field {
        var split = splitSeq(u8, input, ": ");
        const name = split.next().?;
        var nums = tokenizeAny(u8, split.next().?, "- or");

        return Field{
            .name = name,
            .valid_ranges = .{
                .{ try parseInt(u16, nums.next().?, 10), try parseInt(u16, nums.next().?, 10) },
                .{ try parseInt(u16, nums.next().?, 10), try parseInt(u16, nums.next().?, 10) },
            },
        };
    }

    fn contains(self: Field, value: u16) bool {
        const r1, const r2 = self.valid_ranges;
        return inRange(&r1, value) or inRange(&r2, value);
    }

    fn inRange(range: []const u16, value: u16) bool {
        return range[0] <= value and value <= range[1];
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

fn partOne(input: []const u8) !u32 {
    const fields, const tickets = try parseInput(input);
    defer {
        fields.deinit();
        for (tickets.items) |*ticket| {
            ticket.deinit();
        }
        tickets.deinit();
    }

    var scanning_error: u32 = 0;
    for (tickets.items) |ticket| {
        scanning_error += invalidTicketSum(ticket.items, fields.items);
    }
    return scanning_error;
}

fn partTwo(input: []const u8) !u64 {
    const fields, var tickets = try parseInput(input);
    defer {
        fields.deinit();
        for (tickets.items) |*ticket| {
            ticket.deinit();
        }
        tickets.deinit();
    }

    var i_filter: usize = 0;
    while (i_filter < tickets.items.len) {
        if (invalidTicketSum(tickets.items[i_filter].items, fields.items) != 0) {
            _ = tickets.swapRemove(i_filter);
        } else {
            i_filter += 1;
        }
    }

    var fields_mapping = List(List(usize)).init(gpa);
    defer {
        for (fields_mapping.items) |*mappings| {
            mappings.deinit();
        }
        fields_mapping.deinit();
    }
    for (0..fields.items.len) |_| {
        var possible_fields = List(usize).init(gpa);
        for (0..fields.items.len) |j| {
            try possible_fields.append(j);
        }
        try fields_mapping.append(possible_fields);
    }

    for (tickets.items) |ticket| {
        for (ticket.items, 0..) |value, i| {
            var possible_fields = &fields_mapping.items[i];

            var i_field: usize = 0;
            while (i_field < possible_fields.items.len) {
                const field = fields.items[possible_fields.items[i_field]];
                if (!field.contains(value)) {
                    _ = possible_fields.swapRemove(i_field);
                } else {
                    i_field += 1;
                }
            }
        }
    }

    while (!isDone(fields_mapping.items)) {
        for (fields_mapping.items) |mappings| {
            const filter = if (mappings.items.len == 1) mappings.items[0] else continue;
            for (fields_mapping.items) |*other_mappings| {
                if (other_mappings.items.len == 1)
                    continue;
                for (other_mappings.items, 0..) |idx, i| {
                    if (idx == filter) {
                        _ = other_mappings.swapRemove(i);
                        break;
                    }
                }
            }
        }
    }

    var departure: u64 = 1;
    const my_ticket = tickets.items[0].items;
    for (fields_mapping.items, 0..) |mappings, i| {
        const name = fields.items[mappings.items[0]].name;
        if (startsWith(u8, name, "departure")) {
            departure *= my_ticket[i];
        }
    }
    return departure;
}

fn isDone(fields_mapping: []const List(usize)) bool {
    for (fields_mapping) |mappings| {
        if (mappings.items.len > 1)
            return false;
    }
    return true;
}

fn invalidTicketSum(ticket: []const u16, fields: []const Field) u32 {
    var invalid_val: u32 = 0;
    for (ticket) |value| {
        var invalid = true;
        for (fields) |field| {
            if (field.contains(value)) {
                invalid = false;
                break;
            }
        }
        if (invalid)
            invalid_val += value;
    }
    return invalid_val;
}

fn parseInput(input: []const u8) !struct { List(Field), List(List(u16)) } {
    var sections = tokenizeSeq(u8, input, "\n\n");

    var fields = List(Field).init(gpa);
    var fields_it = tokenizeSca(u8, sections.next().?, '\n');
    while (fields_it.next()) |field| {
        try fields.append(try Field.new(field));
    }

    var my_ticket_str = sections.next().?;
    const my_ticket = try parseTicket(my_ticket_str[indexOf(u8, my_ticket_str, '\n').? + 1 ..]);

    var tickets = List(List(u16)).init(gpa);
    try tickets.append(my_ticket);

    var nearby_tickets_str = sections.next().?;
    var nt_it = tokenizeSca(u8, nearby_tickets_str[indexOf(u8, nearby_tickets_str, '\n').? + 1 ..], '\n');
    while (nt_it.next()) |ticket_str| {
        try tickets.append(try parseTicket(ticket_str));
    }

    return .{ fields, tickets };
}

fn parseTicket(input: []const u8) !List(u16) {
    var ticket = List(u16).init(gpa);
    var num_it = tokenizeSca(u8, input, ',');
    while (num_it.next()) |num| {
        try ticket.append(try parseInt(u16, num, 10));
    }
    return ticket;
}
