const std = @import("std");
const util = @import("util.zig");

const List = std.ArrayList;
const StrMap = std.StringHashMap;

const gpa = util.gpa;

const tokenizeSca = std.mem.tokenizeScalar;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const print = std.debug.print;
const sort = std.sort.block;
const equals = std.mem.eql;
const order = std.mem.order;

const data = @embedFile("data/day21.txt");
const data_test = @embedFile("data/day21.test.txt");

const Food = struct {
    ingredients: StrMap(void),
    allergens: List([]const u8),

    fn new(input: []const u8) !Food {
        var split = splitSeq(u8, input, " (contains ");

        var ingredients = StrMap(void).init(gpa);
        var ingred_it = splitSca(u8, split.next().?, ' ');
        while (ingred_it.next()) |ingredient| {
            try ingredients.put(ingredient, {});
        }

        var allergens = List([]const u8).init(gpa);
        if (split.next()) |allergens_str| {
            var split_al = splitSeq(u8, allergens_str[0 .. allergens_str.len - 1], ", ");
            while (split_al.next()) |allergen| {
                try allergens.append(allergen);
            }
        }

        return Food{ .ingredients = ingredients, .allergens = allergens };
    }

    fn deinit(self: *Food) void {
        self.ingredients.deinit();
        self.allergens.deinit();
    }
};

pub fn main() !void {
    const p1_test = try partOne(data_test);
    const p2_test = try partTwo(data_test);
    defer p2_test.deinit();
    print("Test:\n  part 1: {d}\n  part 2: {s}\n\n", .{ p1_test, p2_test.items });

    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    defer p2.deinit();
    print("Puzzle:\n  part 1: {d}\n  part 2: {s}\n", .{ p1, p2.items });
}

fn partOne(input: []const u8) !u32 {
    const foods = try parseInput(input);
    defer {
        for (foods.items) |*food| {
            food.deinit();
        }
        foods.deinit();
    }

    var mappings = try findAllergens(foods.items);
    defer {
        var it = mappings.valueIterator();
        while (it.next()) |ingredients| {
            ingredients.deinit();
        }
        mappings.deinit();
    }

    var allergens = StrMap(void).init(gpa);
    defer allergens.deinit();

    var mapping_it = mappings.valueIterator();
    while (mapping_it.next()) |ingredients| {
        var it = ingredients.keyIterator();
        while (it.next()) |ingredient| {
            try allergens.put(ingredient.*, {});
        }
    }

    var count: u32 = 0;
    for (foods.items) |food| {
        var ingredient_it = food.ingredients.keyIterator();
        while (ingredient_it.next()) |ingredient| {
            if (!allergens.contains(ingredient.*))
                count += 1;
        }
    }
    return count;
}

fn partTwo(input: []const u8) !List(u8) {
    const foods = try parseInput(input);
    defer {
        for (foods.items) |*food| {
            food.deinit();
        }
        foods.deinit();
    }

    var mappings = try findAllergens(foods.items);
    defer {
        var it = mappings.valueIterator();
        while (it.next()) |ingredients| {
            ingredients.deinit();
        }
        mappings.deinit();
    }

    var allergens = List([2][]const u8).init(gpa);
    defer allergens.deinit();

    var allergens_it = mappings.iterator();
    while (allergens_it.next()) |entry| {
        const name = entry.key_ptr.*;
        var it = entry.value_ptr.*.keyIterator();
        try allergens.append(.{ name, it.next().?.* });
    }
    sort([2][]const u8, allergens.items, {}, compare);

    var string_buffer = List(u8).init(gpa);
    for (allergens.items, 0..) |allergen, i| {
        if (i != 0)
            try string_buffer.append(',');
        try string_buffer.appendSlice(allergen[1]);
    }
    return string_buffer;
}

fn compare(_: void, lhs: [2][]const u8, rhs: [2][]const u8) bool {
    return order(u8, lhs[0], rhs[0]) == .lt;
}

fn findAllergens(foods: []const Food) !StrMap(StrMap(void)) {
    var allergen_mappings = StrMap(StrMap(void)).init(gpa);

    for (foods) |food| {
        for (food.allergens.items) |allergen| {
            if (!allergen_mappings.contains(allergen))
                try allergen_mappings.put(allergen, StrMap(void).init(gpa));
            const possible_ingredients = allergen_mappings.getPtr(allergen).?;

            var ingred_it = food.ingredients.keyIterator();
            while (ingred_it.next()) |ingredient| {
                try possible_ingredients.put(ingredient.*, {});
            }
        }
    }

    for (foods) |food| {
        for (food.allergens.items) |allergen| {
            const possible_ingredients = allergen_mappings.getPtr(allergen).?;
            var ingredient_it = possible_ingredients.keyIterator();
            while (ingredient_it.next()) |ingredient| {
                if (!food.ingredients.contains(ingredient.*))
                    _ = possible_ingredients.remove(ingredient.*);
            }
        }
    }

    while (!isDone(allergen_mappings)) {
        var filter_it = allergen_mappings.iterator();
        while (filter_it.next()) |entry| {
            const allergen = entry.key_ptr.*;
            const ingredients = entry.value_ptr.*;
            if (ingredients.count() == 1) {
                var it = ingredients.keyIterator();
                const filter = it.next().?.*;

                var other_it = allergen_mappings.keyIterator();
                while (other_it.next()) |other_allergen| {
                    if (equals(u8, allergen, other_allergen.*))
                        continue;

                    _ = allergen_mappings.getPtr(other_allergen.*).?.remove(filter);
                }
            }
        }
    }

    return allergen_mappings;
}

fn isDone(mappings: StrMap(StrMap(void))) bool {
    var it = mappings.valueIterator();
    while (it.next()) |ingredients| {
        if (ingredients.count() > 1)
            return false;
    }
    return true;
}

fn parseInput(input: []const u8) !List(Food) {
    var foods = List(Food).init(gpa);
    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        try foods.append(try Food.new(line));
    }
    return foods;
}
