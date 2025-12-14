use num_bigint::BigInt;
use std::fs;

struct Problem {
    numbers: Vec<BigInt>,
    operation: char,
}

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let lines: Vec<&str> = input.lines().filter(|l| !l.is_empty()).collect();

    let max_width = lines.iter().map(|l| l.len()).max().unwrap_or(0);
    let padded_lines: Vec<String> = lines
        .iter()
        .map(|l| format!("{:width$}", l, width = max_width))
        .collect();
    let padded_refs: Vec<&str> = padded_lines.iter().map(|s| s.as_str()).collect();

    let problems_part1 = extract_problems(&padded_refs, parse_row_wise);
    let grand_total_part1: BigInt = problems_part1.iter().map(evaluate_problem).sum();
    println!("Part 1: {}", grand_total_part1);

    let problems_part2 = extract_problems(&padded_refs, parse_column_wise);
    let grand_total_part2: BigInt = problems_part2.iter().map(evaluate_problem).sum();
    println!("Part 2: {}", grand_total_part2);
}

fn is_blank_column(lines: &[&str], col: usize) -> bool {
    lines.iter().all(|line| {
        col >= line.len() || line.chars().nth(col).unwrap_or(' ') == ' '
    })
}

fn extract_problems<F>(lines: &[&str], parser: F) -> Vec<Problem>
where
    F: Fn(&[&str], usize, usize) -> Problem,
{
    let width = lines[0].len();
    let mut column_ranges: Vec<(usize, usize)> = Vec::new();
    let mut block_start: Option<usize> = None;

    for col in 0..width {
        let is_blank = is_blank_column(lines, col);
        match (block_start, is_blank) {
            (None, false) => block_start = Some(col),
            (Some(start), true) => {
                column_ranges.push((start, col));
                block_start = None;
            }
            _ => {}
        }
    }

    if let Some(start) = block_start {
        column_ranges.push((start, width));
    }

    column_ranges
        .iter()
        .map(|&(start, end)| parser(lines, start, end))
        .collect()
}

fn parse_row_wise(lines: &[&str], start_col: usize, end_col: usize) -> Problem {
    let mut numbers: Vec<BigInt> = Vec::new();
    let mut operation = '+';

    for line in lines {
        let end = end_col.min(line.len());
        if start_col >= end {
            continue;
        }
        let row_slice = &line[start_col..end];
        let digits: String = row_slice.chars().filter(|c| c.is_ascii_digit()).collect();
        let found_op = row_slice.chars().find(|&c| c == '+' || c == '*');

        if !digits.is_empty() {
            numbers.push(digits.parse().unwrap());
        }
        if let Some(op) = found_op {
            operation = op;
        }
    }

    Problem { numbers, operation }
}

fn parse_column_wise(lines: &[&str], start_col: usize, end_col: usize) -> Problem {
    let mut numbers: Vec<BigInt> = Vec::new();
    let mut operation = '+';

    for col in (start_col..end_col).rev() {
        let column_chars: Vec<char> = lines
            .iter()
            .map(|line| line.chars().nth(col).unwrap_or(' '))
            .collect();

        let digits: String = column_chars.iter().filter(|c| c.is_ascii_digit()).collect();
        let found_op = column_chars.iter().find(|&&c| c == '+' || c == '*');

        if !digits.is_empty() {
            numbers.push(digits.parse().unwrap());
        }
        if let Some(&op) = found_op {
            operation = op;
        }
    }

    numbers.reverse();
    Problem { numbers, operation }
}

fn evaluate_problem(problem: &Problem) -> BigInt {
    match problem.operation {
        '+' => problem.numbers.iter().cloned().sum(),
        '*' => problem.numbers.iter().cloned().product(),
        _ => BigInt::from(0),
    }
}
