const std = @import("std");

const Point = struct {
    x: i64,
    y: i64,
};

const Rectangle = struct {
    min_x: i64,
    max_x: i64,
    min_y: i64,
    max_y: i64,

    fn area(self: Rectangle) i64 {
        return (self.max_x - self.min_x + 1) * (self.max_y - self.min_y + 1);
    }

    fn center(self: Rectangle) struct { x: i64, y: i64 } {
        return .{
            .x = @divTrunc(self.min_x + self.max_x, 2),
            .y = @divTrunc(self.min_y + self.max_y, 2),
        };
    }
};

const HorizontalSegment = struct {
    y: i64,
    x_min: i64,
    x_max: i64,
};

const VerticalSegment = struct {
    x: i64,
    y_min: i64,
    y_max: i64,
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

    var tiles: std.ArrayList(Point) = .empty;
    defer tiles.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;

        var parts = std.mem.splitScalar(u8, trimmed, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        try tiles.append(allocator, Point{ .x = x, .y = y });
    }

    const part1 = findLargestRectangle(tiles.items);
    const part2 = try findLargestRectangleOnPath(allocator, tiles.items);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

fn findLargestRectangle(tiles: []const Point) i64 {
    var max_area: i64 = 0;
    for (0..tiles.len) |i| {
        for (i + 1..tiles.len) |j| {
            const width = @as(i64, @intCast(@abs(tiles[j].x - tiles[i].x))) + 1;
            const height = @as(i64, @intCast(@abs(tiles[j].y - tiles[i].y))) + 1;
            const area = width * height;
            if (area > max_area) max_area = area;
        }
    }
    return max_area;
}

fn findLargestRectangleOnPath(allocator: std.mem.Allocator, tiles: []const Point) !i64 {
    const num_tiles = tiles.len;

    var horizontal_segments: std.ArrayList(HorizontalSegment) = .empty;
    defer horizontal_segments.deinit(allocator);

    var vertical_segments: std.ArrayList(VerticalSegment) = .empty;
    defer vertical_segments.deinit(allocator);

    for (0..num_tiles) |i| {
        const p1 = tiles[i];
        const p2 = tiles[(i + 1) % num_tiles];

        if (p1.y == p2.y) {
            try horizontal_segments.append(allocator, HorizontalSegment{
                .y = p1.y,
                .x_min = @min(p1.x, p2.x),
                .x_max = @max(p1.x, p2.x),
            });
        } else if (p1.x == p2.x) {
            try vertical_segments.append(allocator, VerticalSegment{
                .x = p1.x,
                .y_min = @min(p1.y, p2.y),
                .y_max = @max(p1.y, p2.y),
            });
        }
    }

    var max_area: i64 = 0;
    for (0..num_tiles) |i| {
        for (i + 1..num_tiles) |j| {
            const p1 = tiles[i];
            const p2 = tiles[j];
            const rect = Rectangle{
                .min_x = @min(p1.x, p2.x),
                .max_x = @max(p1.x, p2.x),
                .min_y = @min(p1.y, p2.y),
                .max_y = @max(p1.y, p2.y),
            };

            if (isRectangleValid(rect, horizontal_segments.items, vertical_segments.items, tiles)) {
                const area = rect.area();
                if (area > max_area) max_area = area;
            }
        }
    }

    return max_area;
}

fn isRectangleValid(
    rect: Rectangle,
    horizontal_segments: []const HorizontalSegment,
    vertical_segments: []const VerticalSegment,
    polygon: []const Point,
) bool {
    // Check horizontal segment crossing
    for (horizontal_segments) |seg| {
        if (seg.y > rect.min_y and seg.y < rect.max_y and
            seg.x_min < rect.max_x and seg.x_max > rect.min_x and
            @max(seg.x_min, rect.min_x) < @min(seg.x_max, rect.max_x))
        {
            return false;
        }
    }

    // Check vertical segment crossing
    for (vertical_segments) |seg| {
        if (seg.x > rect.min_x and seg.x < rect.max_x and
            seg.y_min < rect.max_y and seg.y_max > rect.min_y and
            @max(seg.y_min, rect.min_y) < @min(seg.y_max, rect.max_y))
        {
            return false;
        }
    }

    // Check if center is inside polygon
    const c = rect.center();
    return isInsidePolygon(c.x, c.y, polygon);
}

fn isInsidePolygon(test_x: i64, test_y: i64, polygon: []const Point) bool {
    var crossings: u32 = 0;
    const num_points = polygon.len;

    for (0..num_points) |index| {
        const current = polygon[index];
        const previous = polygon[(index + num_points - 1) % num_points];

        if ((current.y > test_y) != (previous.y > test_y)) {
            const intersect_x = current.x +
                @divTrunc((previous.x - current.x) * (test_y - current.y), (previous.y - current.y));
            if (test_x < intersect_x) {
                crossings += 1;
            }
        }
    }

    return crossings % 2 == 1;
}
