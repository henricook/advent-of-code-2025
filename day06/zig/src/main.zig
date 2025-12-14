const std = @import("std");

const Problem = struct {
    numbers: std.ArrayList(u128),
    operation: u8,
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

    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        if (line.len > 0) {
            try lines.append(allocator, line);
        }
    }

    // Pad lines to max width
    var max_width: usize = 0;
    for (lines.items) |line| {
        if (line.len > max_width) max_width = line.len;
    }

    var padded_lines: std.ArrayList([]u8) = .empty;
    defer {
        for (padded_lines.items) |line| allocator.free(line);
        padded_lines.deinit(allocator);
    }

    for (lines.items) |line| {
        var padded = try allocator.alloc(u8, max_width);
        @memcpy(padded[0..line.len], line);
        @memset(padded[line.len..], ' ');
        try padded_lines.append(allocator, padded);
    }

    // Part 1: Row-wise parsing
    var problems_part1 = try extractProblems(allocator, padded_lines.items, parseRowWise);
    defer {
        for (problems_part1.items) |*p| p.numbers.deinit(allocator);
        problems_part1.deinit(allocator);
    }

    var grand_total_part1: u128 = 0;
    for (problems_part1.items) |problem| {
        grand_total_part1 += evaluateProblem(problem);
    }

    // Part 2: Column-wise parsing
    var problems_part2 = try extractProblems(allocator, padded_lines.items, parseColumnWise);
    defer {
        for (problems_part2.items) |*p| p.numbers.deinit(allocator);
        problems_part2.deinit(allocator);
    }

    var grand_total_part2: u128 = 0;
    for (problems_part2.items) |problem| {
        grand_total_part2 += evaluateProblem(problem);
    }

    try stdout.print("Part 1: {d}\n", .{grand_total_part1});
    try stdout.print("Part 2: {d}\n", .{grand_total_part2});
    try stdout.flush();
}

fn isBlankColumn(lines: []const []u8, col: usize) bool {
    for (lines) |line| {
        if (col < line.len and line[col] != ' ') {
            return false;
        }
    }
    return true;
}

const ColumnRange = struct { start: usize, end: usize };
const ParseFn = *const fn (allocator: std.mem.Allocator, lines: []const []u8, start_col: usize, end_col: usize) anyerror!Problem;

fn extractProblems(allocator: std.mem.Allocator, lines: []const []u8, parser: ParseFn) !std.ArrayList(Problem) {
    const width = if (lines.len > 0) lines[0].len else 0;

    var column_ranges: std.ArrayList(ColumnRange) = .empty;
    defer column_ranges.deinit(allocator);

    var block_start: ?usize = null;
    for (0..width) |col| {
        const is_blank = isBlankColumn(lines, col);
        if (block_start == null and !is_blank) {
            block_start = col;
        } else if (block_start != null and is_blank) {
            try column_ranges.append(allocator, .{ .start = block_start.?, .end = col });
            block_start = null;
        }
    }
    if (block_start) |start| {
        try column_ranges.append(allocator, .{ .start = start, .end = width });
    }

    var problems: std.ArrayList(Problem) = .empty;
    for (column_ranges.items) |range| {
        try problems.append(allocator, try parser(allocator, lines, range.start, range.end));
    }

    return problems;
}

fn parseRowWise(allocator: std.mem.Allocator, lines: []const []u8, start_col: usize, end_col: usize) !Problem {
    var numbers: std.ArrayList(u128) = .empty;
    var operation: u8 = '+';

    for (lines) |line| {
        const end = @min(end_col, line.len);
        if (start_col >= end) continue;

        const row_slice = line[start_col..end];

        // Extract digits
        var digits_buf: [64]u8 = undefined;
        var digits_len: usize = 0;
        for (row_slice) |c| {
            if (std.ascii.isDigit(c)) {
                digits_buf[digits_len] = c;
                digits_len += 1;
            }
        }

        if (digits_len > 0) {
            const num = try std.fmt.parseInt(u128, digits_buf[0..digits_len], 10);
            try numbers.append(allocator, num);
        }

        // Find operation
        for (row_slice) |c| {
            if (c == '+' or c == '*') {
                operation = c;
                break;
            }
        }
    }

    return Problem{ .numbers = numbers, .operation = operation };
}

fn parseColumnWise(allocator: std.mem.Allocator, lines: []const []u8, start_col: usize, end_col: usize) !Problem {
    var numbers: std.ArrayList(u128) = .empty;
    var operation: u8 = '+';

    // Process columns right-to-left
    var col = end_col;
    while (col > start_col) {
        col -= 1;

        // Extract column chars
        var digits_buf: [64]u8 = undefined;
        var digits_len: usize = 0;
        var found_op: ?u8 = null;

        for (lines) |line| {
            const c = if (col < line.len) line[col] else ' ';
            if (std.ascii.isDigit(c)) {
                digits_buf[digits_len] = c;
                digits_len += 1;
            }
            if (c == '+' or c == '*') {
                found_op = c;
            }
        }

        if (digits_len > 0) {
            const num = try std.fmt.parseInt(u128, digits_buf[0..digits_len], 10);
            try numbers.append(allocator, num);
        }
        if (found_op) |op| {
            operation = op;
        }
    }

    // Reverse to get left-to-right order
    std.mem.reverse(u128, numbers.items);

    return Problem{ .numbers = numbers, .operation = operation };
}

fn evaluateProblem(problem: Problem) u128 {
    if (problem.numbers.items.len == 0) return 0;

    if (problem.operation == '+') {
        var sum: u128 = 0;
        for (problem.numbers.items) |n| {
            sum += n;
        }
        return sum;
    } else {
        var product: u128 = 1;
        for (problem.numbers.items) |n| {
            product *= n;
        }
        return product;
    }
}
