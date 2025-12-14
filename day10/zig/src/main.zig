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

    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len > 0) {
            try lines.append(allocator, trimmed);
        }
    }

    var total_part1: i32 = 0;
    var total_part2: i32 = 0;

    for (lines.items) |line| {
        total_part1 += try solveMachinePart1(allocator, line);
        total_part2 += try solveMachinePart2(allocator, line);
    }

    try stdout.print("Part 1: {d}\n", .{total_part1});
    try stdout.print("Part 2: {d}\n", .{total_part2});
    try stdout.flush();
}

fn solveMachinePart1(allocator: std.mem.Allocator, line: []const u8) !i32 {
    // Find target pattern [...]
    var target_start: usize = 0;
    var target_end: usize = 0;
    for (line, 0..) |c, i| {
        if (c == '[') target_start = i + 1;
        if (c == ']') {
            target_end = i;
            break;
        }
    }

    const target_str = line[target_start..target_end];
    const num_lights = target_str.len;

    var target = std.AutoHashMap(usize, void).init(allocator);
    defer target.deinit();

    for (target_str, 0..) |c, i| {
        if (c == '#') {
            try target.put(i, {});
        }
    }

    // Find button section (before {)
    var brace_pos = line.len;
    for (line, 0..) |c, i| {
        if (c == '{') {
            brace_pos = i;
            break;
        }
    }

    const button_section = line[0..brace_pos];

    // Parse buttons (...)
    var buttons: std.ArrayList(std.AutoHashMap(usize, void)) = .empty;
    defer {
        for (buttons.items) |*b| b.deinit();
        buttons.deinit(allocator);
    }

    var i: usize = 0;
    while (i < button_section.len) {
        if (button_section[i] == '(') {
            const start = i + 1;
            var end = start;
            while (end < button_section.len and button_section[end] != ')') end += 1;

            var button_set = std.AutoHashMap(usize, void).init(allocator);
            var nums = std.mem.splitScalar(u8, button_section[start..end], ',');
            while (nums.next()) |num_str| {
                const num = try std.fmt.parseInt(usize, num_str, 10);
                try button_set.put(num, {});
            }
            try buttons.append(allocator, button_set);
            i = end + 1;
        } else {
            i += 1;
        }
    }

    return try solveGF2(allocator, num_lights, target, buttons.items);
}

fn solveGF2(
    allocator: std.mem.Allocator,
    num_lights: usize,
    target: std.AutoHashMap(usize, void),
    buttons: []std.AutoHashMap(usize, void),
) !i32 {
    const num_buttons = buttons.len;
    if (num_buttons == 0) return 0;

    // Build augmented matrix
    var matrix = try allocator.alloc([]i32, num_lights);
    defer {
        for (matrix) |row| allocator.free(row);
        allocator.free(matrix);
    }

    for (0..num_lights) |light| {
        matrix[light] = try allocator.alloc(i32, num_buttons + 1);
        for (0..num_buttons) |j| {
            matrix[light][j] = if (buttons[j].contains(light)) 1 else 0;
        }
        matrix[light][num_buttons] = if (target.contains(light)) 1 else 0;
    }

    // Gaussian elimination over GF(2)
    var pivot_row: usize = 0;
    var pivot_cols = try allocator.alloc(i32, num_lights);
    defer allocator.free(pivot_cols);
    for (pivot_cols) |*col| col.* = -1;

    for (0..num_buttons) |col| {
        if (pivot_row >= num_lights) break;

        // Find pivot
        var pivot: ?usize = null;
        for (pivot_row..num_lights) |r| {
            if (matrix[r][col] == 1) {
                pivot = r;
                break;
            }
        }

        if (pivot) |p| {
            // Swap rows
            const tmp = matrix[pivot_row];
            matrix[pivot_row] = matrix[p];
            matrix[p] = tmp;

            pivot_cols[pivot_row] = @intCast(col);

            // Eliminate
            for (0..num_lights) |row| {
                if (row != pivot_row and matrix[row][col] == 1) {
                    for (col..num_buttons + 1) |c| {
                        matrix[row][c] ^= matrix[pivot_row][c];
                    }
                }
            }
            pivot_row += 1;
        }
    }

    // Check inconsistency
    for (pivot_row..num_lights) |row| {
        if (matrix[row][num_buttons] == 1) return 0;
    }

    // Find free variables
    var pivot_col_set = std.AutoHashMap(i32, void).init(allocator);
    defer pivot_col_set.deinit();
    for (pivot_cols) |col_index| {
        if (col_index >= 0) try pivot_col_set.put(col_index, {});
    }

    var free_vars: std.ArrayList(usize) = .empty;
    defer free_vars.deinit(allocator);
    for (0..num_buttons) |c| {
        if (!pivot_col_set.contains(@intCast(c))) {
            try free_vars.append(allocator, c);
        }
    }

    // Find minimum weight solution
    var min_presses: i32 = std.math.maxInt(i32);
    const num_combinations: usize = @as(usize, 1) << @intCast(free_vars.items.len);

    for (0..num_combinations) |mask| {
        var solution = try allocator.alloc(i32, num_buttons);
        defer allocator.free(solution);
        @memset(solution, 0);

        // Set free variables
        for (free_vars.items, 0..) |fv, idx| {
            solution[fv] = @intCast((mask >> @intCast(idx)) & 1);
        }

        // Back-substitute
        var row_idx = pivot_row;
        while (row_idx > 0) {
            row_idx -= 1;
            const pivot_col_value = pivot_cols[row_idx];
            if (pivot_col_value >= 0) {
                const pivot_column_index: usize = @intCast(pivot_col_value);
                var value = matrix[row_idx][num_buttons];
                for (pivot_column_index + 1..num_buttons) |col| {
                    value ^= matrix[row_idx][col] * solution[col];
                }
                solution[pivot_column_index] = value;
            }
        }

        var presses: i32 = 0;
        for (solution) |s| presses += s;
        if (presses < min_presses) min_presses = presses;
    }

    return if (min_presses == std.math.maxInt(i32)) 0 else min_presses;
}

fn solveMachinePart2(allocator: std.mem.Allocator, line: []const u8) !i32 {
    // Find joltage pattern {...}
    var joltage_start: usize = 0;
    var joltage_end: usize = 0;
    for (line, 0..) |c, i| {
        if (c == '{') joltage_start = i + 1;
        if (c == '}') {
            joltage_end = i;
            break;
        }
    }

    var targets: std.ArrayList(i32) = .empty;
    defer targets.deinit(allocator);

    var nums = std.mem.splitScalar(u8, line[joltage_start..joltage_end], ',');
    while (nums.next()) |num_str| {
        try targets.append(allocator, try std.fmt.parseInt(i32, num_str, 10));
    }

    const num_counters = targets.items.len;

    // Find button section
    var brace_pos = line.len;
    for (line, 0..) |c, i| {
        if (c == '{') {
            brace_pos = i;
            break;
        }
    }

    const button_section = line[0..brace_pos];

    // Parse buttons
    var buttons: std.ArrayList(std.AutoHashMap(usize, void)) = .empty;
    defer {
        for (buttons.items) |*b| b.deinit();
        buttons.deinit(allocator);
    }

    var i: usize = 0;
    while (i < button_section.len) {
        if (button_section[i] == '(') {
            const start = i + 1;
            var end = start;
            while (end < button_section.len and button_section[end] != ')') end += 1;

            var button_set = std.AutoHashMap(usize, void).init(allocator);
            var btn_nums = std.mem.splitScalar(u8, button_section[start..end], ',');
            while (btn_nums.next()) |num_str| {
                const num = try std.fmt.parseInt(usize, num_str, 10);
                try button_set.put(num, {});
            }
            try buttons.append(allocator, button_set);
            i = end + 1;
        } else {
            i += 1;
        }
    }

    return try solveLinearSystem(allocator, num_counters, targets.items, buttons.items);
}

fn solveLinearSystem(
    allocator: std.mem.Allocator,
    num_counters: usize,
    targets: []const i32,
    buttons: []std.AutoHashMap(usize, void),
) !i32 {
    const num_buttons = buttons.len;

    // Build augmented matrix
    var augmented = try allocator.alloc([]f64, num_counters);
    defer {
        for (augmented) |row| allocator.free(row);
        allocator.free(augmented);
    }

    for (0..num_counters) |counter_idx| {
        augmented[counter_idx] = try allocator.alloc(f64, num_buttons + 1);
        for (0..num_buttons) |button_idx| {
            augmented[counter_idx][button_idx] = if (buttons[button_idx].contains(counter_idx)) 1.0 else 0.0;
        }
        augmented[counter_idx][num_buttons] = @floatFromInt(targets[counter_idx]);
    }

    // Gaussian elimination
    var pivot_row: usize = 0;
    for (0..num_buttons) |col| {
        if (pivot_row >= num_counters) break;

        // Find best pivot
        var max_row = pivot_row;
        for (pivot_row + 1..num_counters) |row| {
            if (@abs(augmented[row][col]) > @abs(augmented[max_row][col])) {
                max_row = row;
            }
        }

        if (@abs(augmented[max_row][col]) > 1e-10) {
            // Swap
            const tmp = augmented[pivot_row];
            augmented[pivot_row] = augmented[max_row];
            augmented[max_row] = tmp;

            // Normalize
            const pivot = augmented[pivot_row][col];
            for (0..num_buttons + 1) |c| {
                augmented[pivot_row][c] /= pivot;
            }

            // Eliminate
            for (0..num_counters) |row| {
                if (row != pivot_row) {
                    const factor = augmented[row][col];
                    for (0..num_buttons + 1) |c| {
                        augmented[row][c] -= factor * augmented[pivot_row][c];
                    }
                }
            }
            pivot_row += 1;
        }
    }

    // Identify pivot columns
    var pivot_cols = try allocator.alloc(i32, num_counters);
    defer allocator.free(pivot_cols);
    @memset(pivot_cols, -1);

    for (0..pivot_row) |row| {
        for (0..num_buttons) |col| {
            if (@abs(augmented[row][col] - 1.0) < 1e-10 and pivot_cols[row] < 0) {
                pivot_cols[row] = @intCast(col);
            }
        }
    }

    // Find free variables
    var free_vars: std.ArrayList(usize) = .empty;
    defer free_vars.deinit(allocator);

    for (0..num_buttons) |col| {
        var is_pivot = false;
        for (pivot_cols) |pivot_col_value| {
            if (pivot_col_value == @as(i32, @intCast(col))) {
                is_pivot = true;
                break;
            }
        }
        if (!is_pivot) try free_vars.append(allocator, col);
    }

    var solution = try allocator.alloc(f64, num_buttons);
    defer allocator.free(solution);
    @memset(solution, 0.0);

    if (free_vars.items.len == 0) {
        // Direct solution
        var row_idx = pivot_row;
        while (row_idx > 0) {
            row_idx -= 1;
            const pivot_col_value = pivot_cols[row_idx];
            if (pivot_col_value >= 0) {
                const pivot_column_index: usize = @intCast(pivot_col_value);
                var value = augmented[row_idx][num_buttons];
                for (pivot_column_index + 1..num_buttons) |col| {
                    value -= augmented[row_idx][col] * solution[col];
                }
                solution[pivot_column_index] = value;
            }
        }

        var all_valid = true;
        for (solution) |v| {
            const rounded = @round(v);
            if (@abs(v - rounded) >= 1e-6 or rounded < 0) {
                all_valid = false;
                break;
            }
        }

        if (all_valid) {
            var total: i32 = 0;
            for (solution) |v| {
                total += @intFromFloat(@round(v));
            }
            return total;
        }
        return 0;
    } else if (free_vars.items.len <= 3) {
        var max_val: i32 = 0;
        for (targets) |t| {
            if (t > max_val) max_val = t;
        }
        // Cap search space to avoid combinatorial explosion
        max_val = @min(max_val, 200);

        var best_total: i32 = std.math.maxInt(i32);

        // Try all combinations
        var stack: [4]i32 = undefined;
        try tryFreeVarsRecursive(
            allocator,
            0,
            free_vars.items,
            max_val,
            &solution,
            augmented,
            pivot_row,
            pivot_cols,
            num_buttons,
            &best_total,
            &stack,
        );

        return if (best_total == std.math.maxInt(i32)) 0 else best_total;
    } else {
        return try solveGreedy(allocator, num_counters, targets, buttons);
    }
}

fn tryFreeVarsRecursive(
    allocator: std.mem.Allocator,
    idx: usize,
    free_vars: []const usize,
    max_val: i32,
    solution: *[]f64,
    augmented: [][]f64,
    pivot_row: usize,
    pivot_cols: []const i32,
    num_buttons: usize,
    best_total: *i32,
    stack: *[4]i32,
) !void {
    if (idx == free_vars.len) {
        var test_solution = try allocator.alloc(f64, num_buttons);
        defer allocator.free(test_solution);
        @memcpy(test_solution, solution.*);

        var row_idx = pivot_row;
        while (row_idx > 0) {
            row_idx -= 1;
            const pivot_col_value = pivot_cols[row_idx];
            if (pivot_col_value >= 0) {
                const pivot_column_index: usize = @intCast(pivot_col_value);
                var value = augmented[row_idx][num_buttons];
                for (pivot_column_index + 1..num_buttons) |col| {
                    value -= augmented[row_idx][col] * test_solution[col];
                }
                test_solution[pivot_column_index] = value;
            }
        }

        var all_valid = true;
        for (test_solution) |v| {
            const rounded = @round(v);
            if (@abs(v - rounded) >= 1e-6 or rounded < 0) {
                all_valid = false;
                break;
            }
        }

        if (all_valid) {
            var total: i32 = 0;
            for (test_solution) |v| {
                total += @intFromFloat(@round(v));
            }
            if (total < best_total.*) {
                best_total.* = total;
            }
        }
    } else {
        const fv = free_vars[idx];
        var v: i32 = 0;
        while (v <= max_val) : (v += 1) {
            solution.*[fv] = @floatFromInt(v);
            stack[idx] = v;
            try tryFreeVarsRecursive(
                allocator,
                idx + 1,
                free_vars,
                max_val,
                solution,
                augmented,
                pivot_row,
                pivot_cols,
                num_buttons,
                best_total,
                stack,
            );
        }
        solution.*[fv] = 0.0;
    }
}

fn solveGreedy(
    allocator: std.mem.Allocator,
    num_counters: usize,
    targets: []const i32,
    buttons: []std.AutoHashMap(usize, void),
) !i32 {
    const num_buttons = buttons.len;

    var effects = try allocator.alloc([]i32, num_buttons);
    defer {
        for (effects) |e| allocator.free(e);
        allocator.free(effects);
    }

    for (buttons, 0..) |button, button_idx| {
        effects[button_idx] = try allocator.alloc(i32, num_counters);
        for (0..num_counters) |counter_idx| {
            effects[button_idx][counter_idx] = if (button.contains(counter_idx)) 1 else 0;
        }
    }

    var remaining = try allocator.alloc(i32, num_counters);
    defer allocator.free(remaining);
    @memcpy(remaining, targets);

    var presses = try allocator.alloc(i32, num_buttons);
    defer allocator.free(presses);
    @memset(presses, 0);

    while (true) {
        var best_button: i32 = -1;
        var best_times: i32 = 0;
        var best_score: f64 = 0.0;

        for (0..num_buttons) |btn_idx| {
            var max_times: i32 = std.math.maxInt(i32);
            for (0..num_counters) |counter_idx| {
                if (effects[btn_idx][counter_idx] > 0) {
                    max_times = @min(max_times, remaining[counter_idx]);
                }
            }

            if (max_times > 0) {
                var progress: i32 = 0;
                for (effects[btn_idx]) |e| progress += e;
                const score: f64 = @as(f64, @floatFromInt(progress)) * @as(f64, @floatFromInt(max_times));
                if (score > best_score) {
                    best_button = @intCast(btn_idx);
                    best_times = max_times;
                    best_score = score;
                }
            }
        }

        if (best_button < 0 or best_times <= 0) break;

        const bi: usize = @intCast(best_button);
        presses[bi] += best_times;
        for (0..num_counters) |counter_idx| {
            remaining[counter_idx] -= effects[bi][counter_idx] * best_times;
        }
    }

    for (remaining) |r| {
        if (r != 0) return 0;
    }

    var total: i32 = 0;
    for (presses) |p| total += p;
    return total;
}
