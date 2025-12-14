const std = @import("std");

const Box = struct {
    x: i64,
    y: i64,
    z: i64,
};

const Edge = struct {
    distance_squared: f64,
    i: usize,
    j: usize,
};

const UnionFind = struct {
    parent: []usize,
    rank: []usize,
    component_count: usize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, size: usize) !UnionFind {
        var parent = try allocator.alloc(usize, size);
        var rank = try allocator.alloc(usize, size);
        for (0..size) |i| {
            parent[i] = i;
            rank[i] = 0;
        }
        return UnionFind{
            .parent = parent,
            .rank = rank,
            .component_count = size,
            .allocator = allocator,
        };
    }

    fn deinit(self: *UnionFind) void {
        self.allocator.free(self.parent);
        self.allocator.free(self.rank);
    }

    fn find(self: *UnionFind, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.find(self.parent[x]);
        }
        return self.parent[x];
    }

    fn merge(self: *UnionFind, x: usize, y: usize) bool {
        const root_x = self.find(x);
        const root_y = self.find(y);

        if (root_x != root_y) {
            if (self.rank[root_x] < self.rank[root_y]) {
                self.parent[root_x] = root_y;
            } else if (self.rank[root_x] > self.rank[root_y]) {
                self.parent[root_y] = root_x;
            } else {
                self.parent[root_y] = root_x;
                self.rank[root_x] += 1;
            }
            self.component_count -= 1;
            return true;
        }
        return false;
    }

    fn componentSizes(self: *UnionFind, allocator: std.mem.Allocator) !std.AutoHashMap(usize, usize) {
        var sizes = std.AutoHashMap(usize, usize).init(allocator);
        for (0..self.parent.len) |i| {
            const root = self.find(i);
            const existing = sizes.get(root) orelse 0;
            try sizes.put(root, existing + 1);
        }
        return sizes;
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

    var boxes: std.ArrayList(Box) = .empty;
    defer boxes.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;

        var parts = std.mem.splitScalar(u8, trimmed, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        const z = try std.fmt.parseInt(i64, parts.next().?, 10);
        try boxes.append(allocator, Box{ .x = x, .y = y, .z = z });
    }

    var edges = try buildSortedEdges(allocator, boxes.items);
    defer edges.deinit(allocator);

    const part1 = try findTopThreeComponentProduct(allocator, boxes.items.len, edges.items);
    const part2 = try findLastConnectionProduct(allocator, boxes.items, edges.items);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

fn buildSortedEdges(allocator: std.mem.Allocator, boxes: []const Box) !std.ArrayList(Edge) {
    var edges: std.ArrayList(Edge) = .empty;

    for (0..boxes.len) |i| {
        for (i + 1..boxes.len) |j| {
            const dx: f64 = @floatFromInt(boxes[j].x - boxes[i].x);
            const dy: f64 = @floatFromInt(boxes[j].y - boxes[i].y);
            const dz: f64 = @floatFromInt(boxes[j].z - boxes[i].z);
            const distance_squared = dx * dx + dy * dy + dz * dz;
            try edges.append(allocator, Edge{ .distance_squared = distance_squared, .i = i, .j = j });
        }
    }

    std.mem.sort(Edge, edges.items, {}, struct {
        fn lessThan(_: void, a: Edge, b: Edge) bool {
            return a.distance_squared < b.distance_squared;
        }
    }.lessThan);

    return edges;
}

fn findTopThreeComponentProduct(allocator: std.mem.Allocator, num_boxes: usize, sorted_edges: []const Edge) !i64 {
    var uf = try UnionFind.init(allocator, num_boxes);
    defer uf.deinit();

    // Connect using first N edges
    const edges_to_use = @min(num_boxes, sorted_edges.len);
    for (sorted_edges[0..edges_to_use]) |edge| {
        _ = uf.merge(edge.i, edge.j);
    }

    var sizes_map = try uf.componentSizes(allocator);
    defer sizes_map.deinit();

    // Collect sizes
    var sizes: std.ArrayList(i64) = .empty;
    defer sizes.deinit(allocator);

    var iter = sizes_map.valueIterator();
    while (iter.next()) |v| {
        try sizes.append(allocator, @intCast(v.*));
    }

    // Sort descending
    std.mem.sort(i64, sizes.items, {}, struct {
        fn gt(_: void, a: i64, b: i64) bool {
            return a > b;
        }
    }.gt);

    // Product of top 3
    var product: i64 = 1;
    for (sizes.items[0..@min(3, sizes.items.len)]) |s| {
        product *= s;
    }

    return product;
}

fn findLastConnectionProduct(allocator: std.mem.Allocator, boxes: []const Box, sorted_edges: []const Edge) !i64 {
    var uf = try UnionFind.init(allocator, boxes.len);
    defer uf.deinit();

    var last_i: usize = 0;
    var last_j: usize = 0;

    for (sorted_edges) |edge| {
        if (uf.component_count <= 1) break;
        if (uf.merge(edge.i, edge.j)) {
            last_i = edge.i;
            last_j = edge.j;
        }
    }

    return boxes[last_i].x * boxes[last_j].x;
}
