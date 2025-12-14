const std = @import("std");

const Range = struct {
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

    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        try lines.append(allocator, line);
    }

    // Find blank line index
    var blank_index: usize = 0;
    for (lines.items, 0..) |line, i| {
        if (line.len == 0) {
            blank_index = i;
            break;
        }
    }

    // Parse ranges
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(allocator);

    for (lines.items[0..blank_index]) |line| {
        var parts = std.mem.splitScalar(u8, line, '-');
        const start_str = parts.next().?;
        const end_str = parts.next().?;
        try ranges.append(allocator, .{
            .start = try std.fmt.parseInt(i64, start_str, 10),
            .end = try std.fmt.parseInt(i64, end_str, 10),
        });
    }

    // Parse ingredients
    var ingredients: std.ArrayList(i64) = .empty;
    defer ingredients.deinit(allocator);

    for (lines.items[blank_index + 1 ..]) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len > 0) {
            try ingredients.append(allocator, try std.fmt.parseInt(i64, trimmed, 10));
        }
    }

    // Merge ranges
    var merged = try mergeRanges(allocator, ranges.items);
    defer merged.deinit(allocator);

    // Part 1: count fresh ingredients
    var fresh_count: i64 = 0;
    for (ingredients.items) |id| {
        if (isInRange(id, merged.items)) {
            fresh_count += 1;
        }
    }

    // Part 2: total fresh IDs
    var total_fresh: i64 = 0;
    for (merged.items) |range| {
        total_fresh += range.end - range.start + 1;
    }

    try stdout.print("Part 1: {d}\n", .{fresh_count});
    try stdout.print("Part 2: {d}\n", .{total_fresh});
    try stdout.flush();
}

fn mergeRanges(allocator: std.mem.Allocator, ranges: []const Range) !std.ArrayList(Range) {
    const sorted = try allocator.alloc(Range, ranges.len);
    defer allocator.free(sorted);
    @memcpy(sorted, ranges);

    std.mem.sort(Range, sorted, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    var result: std.ArrayList(Range) = .empty;

    for (sorted) |range| {
        if (result.items.len == 0 or result.items[result.items.len - 1].end < range.start - 1) {
            try result.append(allocator, range);
        } else {
            const last_idx = result.items.len - 1;
            result.items[last_idx].end = @max(result.items[last_idx].end, range.end);
        }
    }

    return result;
}

fn isInRange(id: i64, ranges: []const Range) bool {
    var low: usize = 0;
    var high: usize = ranges.len;

    while (low < high) {
        const mid = low + (high - low) / 2;
        const range = ranges[mid];
        if (id < range.start) {
            high = mid;
        } else if (id > range.end) {
            low = mid + 1;
        } else {
            return true;
        }
    }

    return false;
}
