const std = @import("std");

const direction_offsets = [_][2]i32{
    .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
    .{ 0, -1 },              .{ 0, 1 },
    .{ 1, -1 },  .{ 1, 0 },  .{ 1, 1 },
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

    const grid = lines.items;
    const height = grid.len;
    const width = if (height > 0) grid[0].len else 0;

    const part1 = countAccessibleRolls(grid, height, width);
    const part2 = try countTotalRemovable(allocator, grid, height, width);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

fn countNeighbors(row: usize, col: usize, height: usize, width: usize, grid: []const []const u8) u32 {
    var count: u32 = 0;
    for (direction_offsets) |offset| {
        const row_offset = offset[0];
        const col_offset = offset[1];
        const neighbor_row_signed = @as(i64, @intCast(row)) + row_offset;
        const neighbor_col_signed = @as(i64, @intCast(col)) + col_offset;
        if (neighbor_row_signed >= 0 and neighbor_row_signed < height and neighbor_col_signed >= 0 and neighbor_col_signed < width) {
            const neighbor_row: usize = @intCast(neighbor_row_signed);
            const neighbor_col: usize = @intCast(neighbor_col_signed);
            if (grid[neighbor_row][neighbor_col] == '@') {
                count += 1;
            }
        }
    }
    return count;
}

fn isAccessible(row: usize, col: usize, height: usize, width: usize, grid: []const []const u8) bool {
    return countNeighbors(row, col, height, width, grid) < 4;
}

fn countAccessibleRolls(grid: []const []const u8, height: usize, width: usize) u32 {
    var count: u32 = 0;
    for (0..height) |row| {
        for (0..width) |col| {
            if (grid[row][col] == '@' and isAccessible(row, col, height, width, grid)) {
                count += 1;
            }
        }
    }
    return count;
}

fn countTotalRemovable(allocator: std.mem.Allocator, initial_grid: []const []const u8, height: usize, width: usize) !u32 {
    // Create mutable copy of grid
    var grid = try allocator.alloc([]u8, height);
    defer {
        for (grid) |row| allocator.free(row);
        allocator.free(grid);
    }

    for (initial_grid, 0..) |row, idx| {
        grid[idx] = try allocator.alloc(u8, row.len);
        @memcpy(grid[idx], row);
    }

    const Position = struct { row: usize, col: usize };
    var queue: std.ArrayList(Position) = .empty;
    defer queue.deinit(allocator);

    var in_queue = std.AutoHashMap(Position, void).init(allocator);
    defer in_queue.deinit();

    // Seed queue with initially accessible rolls
    for (0..height) |row| {
        for (0..width) |col| {
            if (grid[row][col] == '@' and isAccessibleMutable(row, col, height, width, grid)) {
                try queue.append(allocator, .{ .row = row, .col = col });
                try in_queue.put(.{ .row = row, .col = col }, {});
            }
        }
    }

    var total_removed: u32 = 0;

    while (queue.items.len > 0) {
        const pos = queue.orderedRemove(0);
        _ = in_queue.remove(pos);

        if (grid[pos.row][pos.col] == '@' and isAccessibleMutable(pos.row, pos.col, height, width, grid)) {
            grid[pos.row][pos.col] = '.';
            total_removed += 1;

            // Check neighbors for newly accessible rolls
            for (direction_offsets) |offset| {
                const row_offset = offset[0];
                const col_offset = offset[1];
                const neighbor_row_signed = @as(i64, @intCast(pos.row)) + row_offset;
                const neighbor_col_signed = @as(i64, @intCast(pos.col)) + col_offset;
                if (neighbor_row_signed >= 0 and neighbor_row_signed < height and neighbor_col_signed >= 0 and neighbor_col_signed < width) {
                    const neighbor_row: usize = @intCast(neighbor_row_signed);
                    const neighbor_col: usize = @intCast(neighbor_col_signed);
                    const neighbor = Position{ .row = neighbor_row, .col = neighbor_col };
                    if (grid[neighbor_row][neighbor_col] == '@' and !in_queue.contains(neighbor)) {
                        if (isAccessibleMutable(neighbor_row, neighbor_col, height, width, grid)) {
                            try queue.append(allocator, neighbor);
                            try in_queue.put(neighbor, {});
                        }
                    }
                }
            }
        }
    }

    return total_removed;
}

fn isAccessibleMutable(row: usize, col: usize, height: usize, width: usize, grid: []const []u8) bool {
    var count: u32 = 0;
    for (direction_offsets) |offset| {
        const row_offset = offset[0];
        const col_offset = offset[1];
        const neighbor_row_signed = @as(i64, @intCast(row)) + row_offset;
        const neighbor_col_signed = @as(i64, @intCast(col)) + col_offset;
        if (neighbor_row_signed >= 0 and neighbor_row_signed < height and neighbor_col_signed >= 0 and neighbor_col_signed < width) {
            const neighbor_row: usize = @intCast(neighbor_row_signed);
            const neighbor_col: usize = @intCast(neighbor_col_signed);
            if (grid[neighbor_row][neighbor_col] == '@') {
                count += 1;
            }
        }
    }
    return count < 4;
}
