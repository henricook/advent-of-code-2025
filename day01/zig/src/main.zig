const std = @import("std");

pub fn main() !void {
    var stdout_buf: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    const file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();

    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var part1: i32 = 0;
    var part2: i32 = 0;
    var pos: i32 = 50;

    while (try reader.takeDelimiter('\n')) |raw_line| {
        const line = std.mem.trim(u8, raw_line, &std.ascii.whitespace);
        if (line.len == 0) continue;

        const dir = line[0];
        const dist = try std.fmt.parseInt(i32, line[1..], 10);

        const crossings: i32 = switch (dir) {
            'R' => @divTrunc(pos + dist, 100),
            'L' => blk: {
                if (pos == 0) {
                    break :blk @divTrunc(dist, 100);
                } else if (pos <= dist) {
                    break :blk @divTrunc(dist - pos, 100) + 1;
                } else {
                    break :blk 0;
                }
            },
            else => 0,
        };

        pos = switch (dir) {
            'R' => @mod(pos + dist, 100),
            'L' => @mod(pos - dist, 100),
            else => pos,
        };

        part2 += crossings;
        if (pos == 0) part1 += 1;
    }

    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
    try stdout.flush();
}
