use regex::Regex;
use std::collections::HashSet;
use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let lines: Vec<&str> = input.lines().filter(|l| !l.is_empty()).collect();

    let total_part1: i32 = lines.iter().map(|line| solve_machine_part1(line)).sum();
    println!("Part 1: {}", total_part1);

    let total_part2: i32 = lines.iter().map(|line| solve_machine_part2(line)).sum();
    println!("Part 2: {}", total_part2);
}

fn solve_machine_part1(line: &str) -> i32 {
    let target_re = Regex::new(r"\[([.#]+)\]").unwrap();
    let button_re = Regex::new(r"\(([0-9,]+)\)").unwrap();

    let target_match = target_re.captures(line).unwrap();
    let target_str = &target_match[1];
    let num_lights = target_str.len();
    let target: HashSet<usize> = target_str
        .chars()
        .enumerate()
        .filter(|(_, c)| *c == '#')
        .map(|(i, _)| i)
        .collect();

    let brace_pos = line.find('{').unwrap_or(line.len());
    let button_section = &line[..brace_pos];
    let buttons: Vec<HashSet<usize>> = button_re
        .captures_iter(button_section)
        .map(|cap| {
            cap[1]
                .split(',')
                .map(|s| s.parse().unwrap())
                .collect()
        })
        .collect();

    solve_gf2(num_lights, &target, &buttons)
}

fn solve_gf2(num_lights: usize, target: &HashSet<usize>, buttons: &[HashSet<usize>]) -> i32 {
    let num_buttons = buttons.len();
    if num_buttons == 0 {
        return 0;
    }

    // Build augmented matrix [A | b] over GF(2)
    let mut matrix: Vec<Vec<i32>> = (0..num_lights)
        .map(|light| {
            let mut row = vec![0; num_buttons + 1];
            for (j, button) in buttons.iter().enumerate() {
                if button.contains(&light) {
                    row[j] = 1;
                }
            }
            row[num_buttons] = if target.contains(&light) { 1 } else { 0 };
            row
        })
        .collect();

    // Gaussian elimination with XOR
    let mut pivot_row = 0;
    let mut pivot_cols = vec![-1i32; num_lights];

    for col in 0..num_buttons {
        if pivot_row >= num_lights {
            break;
        }

        // Find a row with 1 in this column
        let pivot = (pivot_row..num_lights).find(|&r| matrix[r][col] == 1);
        if let Some(p) = pivot {
            matrix.swap(pivot_row, p);
            pivot_cols[pivot_row] = col as i32;

            // Eliminate all other 1s in this column using XOR
            for row in 0..num_lights {
                if row != pivot_row && matrix[row][col] == 1 {
                    for i in col..=num_buttons {
                        matrix[row][i] ^= matrix[pivot_row][i];
                    }
                }
            }
            pivot_row += 1;
        }
    }

    // Check for inconsistency
    let has_inconsistency = (pivot_row..num_lights).any(|row| matrix[row][num_buttons] == 1);
    if has_inconsistency {
        return 0;
    }

    // Identify free variables
    let pivot_col_set: HashSet<i32> = pivot_cols.iter().filter(|&&c| c >= 0).copied().collect();
    let free_vars: Vec<usize> = (0..num_buttons)
        .filter(|&c| !pivot_col_set.contains(&(c as i32)))
        .collect();

    // Find minimum weight solution
    let mut min_presses = i32::MAX;

    for mask in 0..(1 << free_vars.len()) {
        let mut solution = vec![0i32; num_buttons];

        // Set free variables according to mask
        for (i, &free_var) in free_vars.iter().enumerate() {
            solution[free_var] = ((mask >> i) & 1) as i32;
        }

        // Back-substitute to find pivot variables
        for row in (0..pivot_row).rev() {
            let pivot_col_value = pivot_cols[row];
            if pivot_col_value >= 0 {
                let pivot_column_index = pivot_col_value as usize;
                let mut value = matrix[row][num_buttons];
                for col in (pivot_column_index + 1)..num_buttons {
                    value ^= matrix[row][col] * solution[col];
                }
                solution[pivot_column_index] = value;
            }
        }

        let presses: i32 = solution.iter().sum();
        min_presses = min_presses.min(presses);
    }

    if min_presses == i32::MAX {
        0
    } else {
        min_presses
    }
}

fn solve_machine_part2(line: &str) -> i32 {
    let button_re = Regex::new(r"\(([0-9,]+)\)").unwrap();
    let joltage_re = Regex::new(r"\{([0-9,]+)\}").unwrap();

    let joltage_match = joltage_re.captures(line).unwrap();
    let targets: Vec<i32> = joltage_match[1]
        .split(',')
        .map(|s| s.parse().unwrap())
        .collect();
    let num_counters = targets.len();

    let brace_pos = line.find('{').unwrap_or(line.len());
    let button_section = &line[..brace_pos];
    let buttons: Vec<HashSet<usize>> = button_re
        .captures_iter(button_section)
        .map(|cap| {
            cap[1]
                .split(',')
                .map(|s| s.parse().unwrap())
                .collect()
        })
        .collect();

    solve_linear_system(num_counters, &targets, &buttons)
}

fn solve_linear_system(
    num_counters: usize,
    targets: &[i32],
    buttons: &[HashSet<usize>],
) -> i32 {
    let num_buttons = buttons.len();

    // Build augmented matrix [A | b]
    let mut augmented: Vec<Vec<f64>> = (0..num_counters)
        .map(|i| {
            let mut row: Vec<f64> = (0..num_buttons)
                .map(|j| if buttons[j].contains(&i) { 1.0 } else { 0.0 })
                .collect();
            row.push(targets[i] as f64);
            row
        })
        .collect();

    // Gaussian elimination with partial pivoting
    let mut pivot_row = 0;
    for col in 0..num_buttons {
        if pivot_row >= num_counters {
            break;
        }

        // Find best pivot
        let mut max_row = pivot_row;
        for row in (pivot_row + 1)..num_counters {
            if augmented[row][col].abs() > augmented[max_row][col].abs() {
                max_row = row;
            }
        }

        if augmented[max_row][col].abs() > 1e-10 {
            augmented.swap(pivot_row, max_row);

            let pivot = augmented[pivot_row][col];
            for i in 0..=num_buttons {
                augmented[pivot_row][i] /= pivot;
            }

            for row in 0..num_counters {
                if row != pivot_row {
                    let factor = augmented[row][col];
                    for i in 0..=num_buttons {
                        augmented[row][i] -= factor * augmented[pivot_row][i];
                    }
                }
            }
            pivot_row += 1;
        }
    }

    // Identify pivot and free variables
    let mut pivot_cols = vec![-1i32; num_counters];
    for row in 0..pivot_row {
        for col in 0..num_buttons {
            if (augmented[row][col] - 1.0).abs() < 1e-10 && pivot_cols[row] < 0 {
                pivot_cols[row] = col as i32;
            }
        }
    }

    let free_vars: Vec<usize> = (0..num_buttons)
        .filter(|&c| !pivot_cols.contains(&(c as i32)))
        .collect();

    let mut solution = vec![0.0f64; num_buttons];
    let mut best_total = i32::MAX;

    if free_vars.is_empty() {
        // No free variables - direct solution
        for row in (0..pivot_row).rev() {
            let pivot_col_value = pivot_cols[row];
            if pivot_col_value >= 0 {
                let pivot_column_index = pivot_col_value as usize;
                let mut value = augmented[row][num_buttons];
                for col in (pivot_column_index + 1)..num_buttons {
                    value -= augmented[row][col] * solution[col];
                }
                solution[pivot_column_index] = value;
            }
        }

        let all_valid = solution.iter().all(|&v| {
            let rounded = v.round() as i32;
            (v - rounded as f64).abs() < 1e-6 && rounded >= 0
        });

        if all_valid {
            solution.iter().map(|&v| v.round() as i32).sum()
        } else {
            0
        }
    } else if free_vars.len() <= 3 {
        // Try all combinations of free variables
        let max_val = *targets.iter().max().unwrap_or(&0);

        fn try_free_vars(
            idx: usize,
            free_vars: &[usize],
            max_val: i32,
            solution: &mut Vec<f64>,
            augmented: &[Vec<f64>],
            pivot_row: usize,
            pivot_cols: &[i32],
            num_buttons: usize,
            best_total: &mut i32,
        ) {
            if idx == free_vars.len() {
                let mut test_solution = solution.clone();
                for row in (0..pivot_row).rev() {
                    let pivot_col_value = pivot_cols[row];
                    if pivot_col_value >= 0 {
                        let pivot_column_index = pivot_col_value as usize;
                        let mut value = augmented[row][num_buttons];
                        for col in (pivot_column_index + 1)..num_buttons {
                            value -= augmented[row][col] * test_solution[col];
                        }
                        test_solution[pivot_column_index] = value;
                    }
                }

                let all_valid = test_solution.iter().all(|&v| {
                    let rounded = v.round() as i32;
                    (v - rounded as f64).abs() < 1e-6 && rounded >= 0
                });

                if all_valid {
                    let total: i32 = test_solution.iter().map(|&v| v.round() as i32).sum();
                    if total < *best_total {
                        *best_total = total;
                    }
                }
            } else {
                let free_var = free_vars[idx];
                for v in 0..=max_val {
                    solution[free_var] = v as f64;
                    try_free_vars(
                        idx + 1,
                        free_vars,
                        max_val,
                        solution,
                        augmented,
                        pivot_row,
                        pivot_cols,
                        num_buttons,
                        best_total,
                    );
                }
                solution[free_var] = 0.0;
            }
        }

        try_free_vars(
            0,
            &free_vars,
            max_val,
            &mut solution,
            &augmented,
            pivot_row,
            &pivot_cols,
            num_buttons,
            &mut best_total,
        );

        if best_total == i32::MAX {
            0
        } else {
            best_total
        }
    } else {
        solve_greedy_with_search(num_counters, targets, buttons)
    }
}

fn solve_greedy_with_search(
    num_counters: usize,
    targets: &[i32],
    buttons: &[HashSet<usize>],
) -> i32 {
    let num_buttons = buttons.len();
    let effects: Vec<Vec<i32>> = buttons
        .iter()
        .map(|button_set| {
            (0..num_counters)
                .map(|i| if button_set.contains(&i) { 1 } else { 0 })
                .collect()
        })
        .collect();

    let mut remaining: Vec<i32> = targets.to_vec();
    let mut presses = vec![0i32; num_buttons];

    loop {
        let mut best_button = -1i32;
        let mut best_times = 0;
        let mut best_score = 0.0;

        for button_idx in 0..num_buttons {
            let effect = &effects[button_idx];
            let mut max_times = i32::MAX;
            for i in 0..num_counters {
                if effect[i] > 0 {
                    max_times = max_times.min(remaining[i]);
                }
            }

            if max_times > 0 {
                let progress: i32 = effect.iter().sum();
                let score = progress as f64 * max_times as f64;
                if score > best_score {
                    best_button = button_idx as i32;
                    best_times = max_times;
                    best_score = score;
                }
            }
        }

        if best_button < 0 || best_times <= 0 {
            break;
        }

        let bi = best_button as usize;
        presses[bi] += best_times;
        for i in 0..num_counters {
            remaining[i] -= effects[bi][i] * best_times;
        }
    }

    if remaining.iter().all(|&r| r == 0) {
        presses.iter().sum()
    } else {
        0
    }
}
