use std::collections::{HashMap, HashSet};
use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let grid: Vec<&str> = input.lines().collect();

    println!("Part 1: {}", simulate_beam(&grid));
    println!("Part 2: {}", count_timelines(&grid));
}

fn simulate_beam(grid: &[&str]) -> usize {
    let height = grid.len();
    let width = if height > 0 { grid[0].len() } else { 0 };

    let start_row = grid.iter().position(|line| line.contains('S')).unwrap();
    let start_col = grid[start_row].find('S').unwrap();

    let mut active_columns: HashSet<i32> = HashSet::new();
    active_columns.insert(start_col as i32);

    let mut total_splitter_hits = 0;

    for row in (start_row + 1)..height {
        if active_columns.is_empty() {
            break;
        }

        let new_hits = active_columns
            .iter()
            .filter(|&&col| {
                col >= 0
                    && (col as usize) < width
                    && grid[row].chars().nth(col as usize) == Some('^')
            })
            .count();

        total_splitter_hits += new_hits;

        let next_columns: HashSet<i32> = active_columns
            .iter()
            .flat_map(|&col| {
                if col >= 0
                    && (col as usize) < width
                    && grid[row].chars().nth(col as usize) == Some('^')
                {
                    vec![col - 1, col + 1]
                } else {
                    vec![col]
                }
            })
            .filter(|&col| col >= 0 && (col as usize) < width)
            .collect();

        active_columns = next_columns;
    }

    total_splitter_hits
}

fn count_timelines(grid: &[&str]) -> u64 {
    let height = grid.len();
    let width = if height > 0 { grid[0].len() } else { 0 };

    let start_row = grid.iter().position(|line| line.contains('S')).unwrap();
    let start_col = grid[start_row].find('S').unwrap();

    let mut timeline_count_by_column: HashMap<i32, u64> = HashMap::new();
    timeline_count_by_column.insert(start_col as i32, 1);

    for row in (start_row + 1)..height {
        if timeline_count_by_column.is_empty() {
            break;
        }

        let mut new_counts: HashMap<i32, u64> = HashMap::new();

        for (&col, &count) in &timeline_count_by_column {
            if col >= 0
                && (col as usize) < width
                && grid[row].chars().nth(col as usize) == Some('^')
            {
                // Split: timeline goes both left and right
                if col - 1 >= 0 {
                    *new_counts.entry(col - 1).or_insert(0) += count;
                }
                if (col + 1) < width as i32 {
                    *new_counts.entry(col + 1).or_insert(0) += count;
                }
            } else {
                *new_counts.entry(col).or_insert(0) += count;
            }
        }

        timeline_count_by_column = new_counts
            .into_iter()
            .filter(|&(col, _)| col >= 0 && (col as usize) < width)
            .collect();
    }

    timeline_count_by_column.values().sum()
}
