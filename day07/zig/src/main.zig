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

    var grid: std.ArrayList([]const u8) = .empty;
    defer grid.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        if (line.len > 0) {
            try grid.append(allocator, line);
        }
    }

    const part1 = try simulateBeam(allocator, grid.items);
    const part2 = try countTimelines(allocator, grid.items);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

fn simulateBeam(allocator: std.mem.Allocator, grid: []const []const u8) !u32 {
    const height = grid.len;
    const width = if (height > 0) grid[0].len else 0;

    // Find start position
    var start_row: usize = 0;
    var start_col: usize = 0;
    for (grid, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c == 'S') {
                start_row = row;
                start_col = col;
                break;
            }
        }
    }

    var active_columns = std.AutoHashMap(i32, void).init(allocator);
    defer active_columns.deinit();
    try active_columns.put(@intCast(start_col), {});

    var total_splitter_hits: u32 = 0;

    for (start_row + 1..height) |row| {
        if (active_columns.count() == 0) break;

        // Count hits
        var iter = active_columns.keyIterator();
        while (iter.next()) |col_ptr| {
            const col = col_ptr.*;
            if (col >= 0 and col < width) {
                const c: usize = @intCast(col);
                if (grid[row][c] == '^') {
                    total_splitter_hits += 1;
                }
            }
        }

        // Calculate next columns
        var next_columns = std.AutoHashMap(i32, void).init(allocator);
        iter = active_columns.keyIterator();
        while (iter.next()) |col_ptr| {
            const col = col_ptr.*;
            if (col >= 0 and col < width) {
                const c: usize = @intCast(col);
                if (grid[row][c] == '^') {
                    if (col - 1 >= 0 and col - 1 < width) {
                        try next_columns.put(col - 1, {});
                    }
                    if (col + 1 >= 0 and col + 1 < width) {
                        try next_columns.put(col + 1, {});
                    }
                } else {
                    try next_columns.put(col, {});
                }
            }
        }

        active_columns.deinit();
        active_columns = next_columns;
    }

    return total_splitter_hits;
}

fn countTimelines(allocator: std.mem.Allocator, grid: []const []const u8) !u64 {
    const height = grid.len;
    const width: i32 = if (height > 0) @intCast(grid[0].len) else 0;

    // Find start position
    var start_row: usize = 0;
    var start_col: i32 = 0;
    for (grid, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c == 'S') {
                start_row = row;
                start_col = @intCast(col);
                break;
            }
        }
    }

    var timeline_counts = std.AutoHashMap(i32, u64).init(allocator);
    defer timeline_counts.deinit();
    try timeline_counts.put(start_col, 1);

    for (start_row + 1..height) |row| {
        if (timeline_counts.count() == 0) break;

        var new_counts = std.AutoHashMap(i32, u64).init(allocator);

        var iter = timeline_counts.iterator();
        while (iter.next()) |entry| {
            const col = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (col >= 0 and col < width) {
                const c: usize = @intCast(col);
                if (grid[row][c] == '^') {
                    // Split
                    if (col - 1 >= 0) {
                        const existing = new_counts.get(col - 1) orelse 0;
                        try new_counts.put(col - 1, existing + count);
                    }
                    if (col + 1 < width) {
                        const existing = new_counts.get(col + 1) orelse 0;
                        try new_counts.put(col + 1, existing + count);
                    }
                } else {
                    const existing = new_counts.get(col) orelse 0;
                    try new_counts.put(col, existing + count);
                }
            }
        }

        timeline_counts.deinit();
        timeline_counts = new_counts;
    }

    var total: u64 = 0;
    var iter = timeline_counts.valueIterator();
    while (iter.next()) |v| {
        total += v.*;
    }

    return total;
}
