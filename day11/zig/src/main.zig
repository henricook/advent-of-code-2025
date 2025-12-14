const std = @import("std");

const Graph = std.StringHashMap(std.ArrayList([]const u8));

const MemoKey = struct {
    node: []const u8,
    has_req1: bool,
    has_req2: bool,
};

const MemoKeyContext = struct {
    pub fn hash(_: @This(), key: MemoKey) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(key.node);
        h.update(&[_]u8{ @intFromBool(key.has_req1), @intFromBool(key.has_req2) });
        return h.final();
    }
    pub fn eql(_: @This(), a: MemoKey, b: MemoKey) bool {
        return std.mem.eql(u8, a.node, b.node) and a.has_req1 == b.has_req1 and a.has_req2 == b.has_req2;
    }
};

const Memo2Type = std.HashMap(MemoKey, u128, MemoKeyContext, std.hash_map.default_max_load_percentage);

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

    var graph = Graph.init(allocator);
    defer {
        var iter = graph.valueIterator();
        while (iter.next()) |v| v.deinit(allocator);
        graph.deinit();
    }

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;

        var parts = std.mem.splitSequence(u8, trimmed, ": ");
        const source = parts.next().?;
        const targets_str = parts.next().?;

        var targets: std.ArrayList([]const u8) = .empty;
        var target_iter = std.mem.splitScalar(u8, targets_str, ' ');
        while (target_iter.next()) |t| {
            try targets.append(allocator, t);
        }

        try graph.put(source, targets);
    }

    var memo1 = std.StringHashMap(u128).init(allocator);
    defer memo1.deinit();
    const part1 = countPaths(&graph, "you", "out", &memo1);

    var memo2 = Memo2Type.init(allocator);
    defer memo2.deinit();

    const part2 = countPathsWithBoth(&graph, "svr", "out", "dac", "fft", false, false, &memo2);

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}

fn countPaths(
    graph: *const Graph,
    node: []const u8,
    end: []const u8,
    memo: *std.StringHashMap(u128),
) u128 {
    if (std.mem.eql(u8, node, end)) return 1;

    if (memo.get(node)) |cached| return cached;

    const targets = graph.get(node) orelse return 0;

    var total: u128 = 0;
    for (targets.items) |next| {
        total += countPaths(graph, next, end, memo);
    }

    memo.put(node, total) catch {};
    return total;
}

fn countPathsWithBoth(
    graph: *const Graph,
    node: []const u8,
    end: []const u8,
    req1: []const u8,
    req2: []const u8,
    has_req1: bool,
    has_req2: bool,
    memo: *Memo2Type,
) u128 {
    const now_has_req1 = has_req1 or std.mem.eql(u8, node, req1);
    const now_has_req2 = has_req2 or std.mem.eql(u8, node, req2);

    if (std.mem.eql(u8, node, end)) {
        return if (now_has_req1 and now_has_req2) 1 else 0;
    }

    const key = MemoKey{ .node = node, .has_req1 = now_has_req1, .has_req2 = now_has_req2 };
    if (memo.get(key)) |cached| return cached;

    const targets = graph.get(node) orelse return 0;

    var total: u128 = 0;
    for (targets.items) |next| {
        total += countPathsWithBoth(graph, next, end, req1, req2, now_has_req1, now_has_req2, memo);
    }

    memo.put(key, total) catch {};
    return total;
}
