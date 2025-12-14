const std = @import("std");

const Cell = struct { row: i32, col: i32 };

const Bounds = struct { width: i32, height: i32 };

const Shape = struct {
    cells: std.AutoHashMap(Cell, void),

    fn deinit(self: *Shape) void {
        self.cells.deinit();
    }
};

const Region = struct {
    width: i32,
    height: i32,
    shape_counts: std.ArrayList(i32),

    fn deinit(self: *Region, allocator: std.mem.Allocator) void {
        self.shape_counts.deinit(allocator);
    }
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

    var shapes: std.ArrayList(Shape) = .empty;
    defer {
        for (shapes.items) |*s| s.deinit();
        shapes.deinit(allocator);
    }

    var regions: std.ArrayList(Region) = .empty;
    defer {
        for (regions.items) |*r| r.deinit(allocator);
        regions.deinit(allocator);
    }

    var index: usize = 0;
    while (index < lines.items.len) {
        const line = lines.items[index];

        // Check for shape definition (digit followed by colon, no 'x')
        if (line.len > 0 and std.ascii.isDigit(line[0]) and
            std.mem.indexOfScalar(u8, line, ':') != null and
            std.mem.indexOfScalar(u8, line, 'x') == null)
        {
            var shape_lines: std.ArrayList([]const u8) = .empty;
            defer shape_lines.deinit(allocator);

            index += 1;
            while (index < lines.items.len) {
                const shape_line = lines.items[index];
                if (shape_line.len == 0) break;
                if (std.mem.indexOfScalar(u8, shape_line, 'x') != null) break;
                if (shape_line.len > 0 and std.ascii.isDigit(shape_line[0]) and
                    std.mem.indexOfScalar(u8, shape_line, ':') != null)
                {
                    break;
                }
                try shape_lines.append(allocator, shape_line);
                index += 1;
            }

            var cells = std.AutoHashMap(Cell, void).init(allocator);
            for (shape_lines.items, 0..) |row, row_idx| {
                for (row, 0..) |ch, col_idx| {
                    if (ch == '#') {
                        try cells.put(.{ .row = @intCast(row_idx), .col = @intCast(col_idx) }, {});
                    }
                }
            }
            try shapes.append(allocator, Shape{ .cells = cells });
        } else if (std.mem.indexOfScalar(u8, line, 'x') != null and std.mem.indexOfScalar(u8, line, ':') != null) {
            // Region definition
            var parts = std.mem.splitSequence(u8, line, ": ");
            const dimensions_str = parts.next().?;
            const counts_str = parts.next().?;

            var dim_parts = std.mem.splitScalar(u8, dimensions_str, 'x');
            const width = try std.fmt.parseInt(i32, dim_parts.next().?, 10);
            const height = try std.fmt.parseInt(i32, dim_parts.next().?, 10);

            var shape_counts: std.ArrayList(i32) = .empty;
            var count_iter = std.mem.splitScalar(u8, counts_str, ' ');
            while (count_iter.next()) |count_str| {
                const trimmed = std.mem.trim(u8, count_str, &std.ascii.whitespace);
                if (trimmed.len > 0) {
                    try shape_counts.append(allocator, try std.fmt.parseInt(i32, trimmed, 10));
                }
            }

            try regions.append(allocator, Region{
                .width = width,
                .height = height,
                .shape_counts = shape_counts,
            });
            index += 1;
        } else {
            index += 1;
        }
    }

    // Calculate shape properties
    var shape_cell_counts = try allocator.alloc(i32, shapes.items.len);
    defer allocator.free(shape_cell_counts);

    var shape_bounds = try allocator.alloc(Bounds, shapes.items.len);
    defer allocator.free(shape_bounds);

    for (shapes.items, 0..) |shape, i| {
        shape_cell_counts[i] = @intCast(shape.cells.count());
        shape_bounds[i] = boundingBox(&shape);
    }

    var fit_count: u32 = 0;
    for (regions.items) |region| {
        if (canFitPresents(region, shape_cell_counts, shape_bounds)) {
            fit_count += 1;
        }
    }

    try stdout.print("Part 1: {d}\n", .{fit_count});
    try stdout.print("Part 2: Merry Christmas!\n", .{});
    try stdout.flush();
}

fn boundingBox(shape: *const Shape) Bounds {
    if (shape.cells.count() == 0) return Bounds{ .width = 0, .height = 0 };

    var min_row: i32 = std.math.maxInt(i32);
    var max_row: i32 = std.math.minInt(i32);
    var min_col: i32 = std.math.maxInt(i32);
    var max_col: i32 = std.math.minInt(i32);

    var iter = shape.cells.keyIterator();
    while (iter.next()) |cell| {
        if (cell.row < min_row) min_row = cell.row;
        if (cell.row > max_row) max_row = cell.row;
        if (cell.col < min_col) min_col = cell.col;
        if (cell.col > max_col) max_col = cell.col;
    }

    return .{
        .width = max_row - min_row + 1,
        .height = max_col - min_col + 1,
    };
}

fn canFitPresents(
    region: Region,
    shape_cell_counts: []const i32,
    shape_bounds: []const Bounds,
) bool {
    // Check total area
    var total_cells_needed: i64 = 0;
    for (region.shape_counts.items, 0..) |count, i| {
        if (i < shape_cell_counts.len) {
            total_cells_needed += @as(i64, count) * @as(i64, shape_cell_counts[i]);
        }
    }

    const region_area: i64 = @as(i64, region.width) * @as(i64, region.height);
    if (total_cells_needed > region_area) return false;

    // Check bounding boxes
    for (region.shape_counts.items, 0..) |count, i| {
        if (i >= shape_bounds.len) continue;
        if (count == 0) continue;

        const shape_w = shape_bounds[i].width;
        const shape_h = shape_bounds[i].height;

        const fits_normal = shape_w <= region.width and shape_h <= region.height;
        const fits_rotated = shape_h <= region.width and shape_w <= region.height;

        if (!fits_normal and !fits_rotated) return false;
    }

    return true;
}
