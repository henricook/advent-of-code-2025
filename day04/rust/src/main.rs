use std::collections::{HashSet, VecDeque};
use std::fs;

const DIRECTION_OFFSETS: [(i32, i32); 8] = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1),           (0, 1),
    (1, -1),  (1, 0),  (1, 1),
];

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let grid: Vec<&str> = input.lines().collect();

    println!("Part 1: {}", count_accessible_rolls(&grid));
    println!("Part 2: {}", count_total_removable(&grid));
}

fn count_neighbors(row: i32, col: i32, height: i32, width: i32, grid: &[Vec<char>]) -> usize {
    DIRECTION_OFFSETS.iter().filter(|(row_offset, col_offset)| {
        let neighbor_row = row + row_offset;
        let neighbor_col = col + col_offset;
        neighbor_row >= 0
            && neighbor_row < height
            && neighbor_col >= 0
            && neighbor_col < width
            && grid[neighbor_row as usize][neighbor_col as usize] == '@'
    }).count()
}

fn is_accessible(row: i32, col: i32, height: i32, width: i32, grid: &[Vec<char>]) -> bool {
    count_neighbors(row, col, height, width, grid) < 4
}

fn count_accessible_rolls(grid: &[&str]) -> usize {
    let height = grid.len() as i32;
    let width = grid[0].len() as i32;

    let char_grid: Vec<Vec<char>> = grid.iter().map(|row| row.chars().collect()).collect();

    let mut count = 0;
    for row in 0..height {
        for col in 0..width {
            if char_grid[row as usize][col as usize] == '@'
                && is_accessible(row, col, height, width, &char_grid)
            {
                count += 1;
            }
        }
    }
    count
}

fn count_total_removable(grid: &[&str]) -> usize {
    let height = grid.len() as i32;
    let width = grid[0].len() as i32;

    let mut char_grid: Vec<Vec<char>> = grid.iter().map(|row| row.chars().collect()).collect();

    let mut queue: VecDeque<(i32, i32)> = VecDeque::new();
    let mut in_queue: HashSet<(i32, i32)> = HashSet::new();

    // Seed queue with all initially accessible rolls
    for row in 0..height {
        for col in 0..width {
            if char_grid[row as usize][col as usize] == '@'
                && is_accessible(row, col, height, width, &char_grid)
            {
                queue.push_back((row, col));
                in_queue.insert((row, col));
            }
        }
    }

    let mut total_removed = 0;

    while let Some((row, col)) = queue.pop_front() {
        in_queue.remove(&(row, col));

        // Check if still a roll and still accessible
        if char_grid[row as usize][col as usize] == '@'
            && is_accessible(row, col, height, width, &char_grid)
        {
            char_grid[row as usize][col as usize] = '.';
            total_removed += 1;

            // Check if any neighbors became newly accessible
            for (row_offset, col_offset) in DIRECTION_OFFSETS {
                let (neighbor_row, neighbor_col) = (row + row_offset, col + col_offset);
                if neighbor_row >= 0 && neighbor_row < height && neighbor_col >= 0 && neighbor_col < width {
                    if char_grid[neighbor_row as usize][neighbor_col as usize] == '@'
                        && !in_queue.contains(&(neighbor_row, neighbor_col))
                        && is_accessible(neighbor_row, neighbor_col, height, width, &char_grid)
                    {
                        queue.push_back((neighbor_row, neighbor_col));
                        in_queue.insert((neighbor_row, neighbor_col));
                    }
                }
            }
        }
    }

    total_removed
}
