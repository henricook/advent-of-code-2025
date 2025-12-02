const std = @import("std");

const IdRange = struct {
    start: i64,
    end: i64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buf: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    const file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);

    var ranges: std.ArrayList(IdRange) = .empty;
    defer ranges.deinit(allocator);

    var range_iter = std.mem.splitScalar(u8, trimmed, ',');
    while (range_iter.next()) |range_str| {
        var parts = std.mem.splitScalar(u8, range_str, '-');
        const start_str = parts.next().?;
        const end_str = parts.next().?;
        try ranges.append(allocator, .{
            .start = try std.fmt.parseInt(i64, start_str, 10),
            .end = try std.fmt.parseInt(i64, end_str, 10),
        });
    }

    const part1 = sumMirroredIds(ranges.items);
    const part2 = try sumRepeatedPatternIds(allocator, ranges.items);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

// Part 1: Numbers where first half equals second half (e.g., 123123)
fn sumMirroredIds(ranges: []const IdRange) i64 {
    var total: i64 = 0;
    for (ranges) |range| {
        total += sumMirroredInRange(range);
    }
    return total;
}

fn sumMirroredInRange(range: IdRange) i64 {
    const max_digits = digitCount(range.end);
    const max_half_length = @divTrunc(max_digits + 1, 2);

    var total: i64 = 0;
    var half_length: i32 = 1;
    while (half_length <= max_half_length) : (half_length += 1) {
        const mirror_multiplier = powerOf10(half_length) + 1;
        const smallest_valid_half: i64 = if (half_length == 1) 1 else powerOf10(half_length - 1);
        const largest_valid_half = powerOf10(half_length) - 1;

        const smallest_half_in_range = @max(smallest_valid_half, ceilDiv(range.start, mirror_multiplier));
        const largest_half_in_range = @min(largest_valid_half, @divTrunc(range.end, mirror_multiplier));

        if (smallest_half_in_range <= largest_half_in_range) {
            const count = largest_half_in_range - smallest_half_in_range + 1;
            total += @divTrunc(mirror_multiplier * count * (smallest_half_in_range + largest_half_in_range), 2);
        }
    }
    return total;
}

// Part 2: Numbers made of a pattern repeated at least twice
fn sumRepeatedPatternIds(allocator: std.mem.Allocator, ranges: []const IdRange) !i64 {
    var max_value: i64 = 0;
    for (ranges) |range| {
        if (range.end > max_value) max_value = range.end;
    }

    var repeated_numbers: std.ArrayList(i64) = .empty;
    defer repeated_numbers.deinit(allocator);

    try generateAllRepeatedPatternNumbers(allocator, &repeated_numbers, max_value);

    // Sort and deduplicate
    std.mem.sort(i64, repeated_numbers.items, {}, std.sort.asc(i64));

    var total: i64 = 0;
    for (ranges) |range| {
        var prev: ?i64 = null;
        for (repeated_numbers.items) |num| {
            // Skip duplicates
            if (prev != null and prev.? == num) continue;
            prev = num;

            if (num >= range.start and num <= range.end) {
                total += num;
            }
        }
    }
    return total;
}

fn generateAllRepeatedPatternNumbers(allocator: std.mem.Allocator, result: *std.ArrayList(i64), max_value: i64) !void {
    const max_digit_count = digitCount(max_value);

    var total_digit_count: i32 = 2;
    while (total_digit_count <= max_digit_count) : (total_digit_count += 1) {
        var pattern_digit_count: i32 = 1;
        while (pattern_digit_count < total_digit_count) : (pattern_digit_count += 1) {
            if (@rem(total_digit_count, pattern_digit_count) != 0) continue;

            const repetition_count = @divTrunc(total_digit_count, pattern_digit_count);
            if (repetition_count < 2) continue;

            const repeat_multiplier = computeRepeatMultiplier(pattern_digit_count, repetition_count);
            const smallest_pattern: i64 = if (pattern_digit_count == 1) 1 else powerOf10(pattern_digit_count - 1);
            const largest_pattern = powerOf10(pattern_digit_count) - 1;

            var base_pattern = smallest_pattern;
            while (base_pattern <= largest_pattern) : (base_pattern += 1) {
                const repeated_number = base_pattern * repeat_multiplier;
                if (repeated_number <= max_value) {
                    try result.append(allocator, repeated_number);
                }
            }
        }
    }
}

fn computeRepeatMultiplier(pattern_digit_count: i32, repetition_count: i32) i64 {
    const total_digit_count = pattern_digit_count * repetition_count;
    return @divTrunc(powerOf10(total_digit_count) - 1, powerOf10(pattern_digit_count) - 1);
}

fn powerOf10(exponent: i32) i64 {
    var result: i64 = 1;
    var i: i32 = 0;
    while (i < exponent) : (i += 1) {
        result *= 10;
    }
    return result;
}

fn digitCount(n: i64) i32 {
    var count: i32 = 0;
    var value = n;
    while (value > 0) {
        value = @divTrunc(value, 10);
        count += 1;
    }
    return count;
}

fn ceilDiv(numerator: i64, denominator: i64) i64 {
    return @divTrunc(numerator + denominator - 1, denominator);
}
