const std = @import("std");

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

    var banks: std.ArrayList([]const u8) = .empty;
    defer banks.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len > 0) {
            try banks.append(allocator, trimmed);
        }
    }

    const part1 = totalMaxJoltage(banks.items, 2);
    const part2 = totalMaxJoltage(banks.items, 12);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

fn totalMaxJoltage(banks: []const []const u8, digits_to_select: usize) i64 {
    var total: i64 = 0;
    for (banks) |bank| {
        total += maxJoltageForBank(bank, digits_to_select);
    }
    return total;
}

fn maxJoltageForBank(bank: []const u8, digits_to_select: usize) i64 {
    var selected: [12]i64 = undefined;
    var start_index: usize = 0;

    for (0..digits_to_select) |position| {
        // Must leave (digits_to_select - position - 1) digits after this pick
        const end_index = bank.len - (digits_to_select - position - 1);
        const result = findMaxInRange(bank, start_index, end_index);
        selected[position] = result.max_digit;
        start_index = result.max_index + 1;
    }

    var joltage: i64 = 0;
    for (0..digits_to_select) |i| {
        joltage = joltage * 10 + selected[i];
    }
    return joltage;
}

const MaxResult = struct {
    max_digit: i64,
    max_index: usize,
};

fn findMaxInRange(bank: []const u8, start: usize, end: usize) MaxResult {
    var max_digit: i64 = -1;
    var max_index: usize = start;

    for (start..end) |i| {
        const digit: i64 = @intCast(bank[i] - '0');
        if (digit > max_digit) {
            max_digit = digit;
            max_index = i;
        }
    }

    return .{ .max_digit = max_digit, .max_index = max_index };
}
