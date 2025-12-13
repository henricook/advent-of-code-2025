use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let banks: Vec<&str> = input.lines().filter(|l| !l.is_empty()).collect();

    println!("Part 1: {}", total_max_joltage(&banks, 2));
    println!("Part 2: {}", total_max_joltage(&banks, 12));
}

fn total_max_joltage(banks: &[&str], digits_to_select: usize) -> i64 {
    banks.iter().map(|bank| max_joltage_for_bank(bank, digits_to_select)).sum()
}

fn max_joltage_for_bank(bank: &str, digits_to_select: usize) -> i64 {
    let digits: Vec<i64> = bank.chars().map(|c| c.to_digit(10).unwrap() as i64).collect();
    let selected = select_max_digits(&digits, digits_to_select);
    selected.iter().fold(0i64, |acc, &digit| acc * 10 + digit)
}

fn select_max_digits(digits: &[i64], count: usize) -> Vec<i64> {
    // Greedy: for each position, pick the largest digit while leaving enough for remaining
    let mut result = Vec::with_capacity(count);
    let mut start_index = 0;

    for position in 0..count {
        // Must leave (count - position - 1) digits after this pick
        let end_index = digits.len() - (count - position - 1);
        let (max_digit, max_index) = find_max_in_range(digits, start_index, end_index);
        result.push(max_digit);
        start_index = max_index + 1;
    }

    result
}

fn find_max_in_range(digits: &[i64], start: usize, end: usize) -> (i64, usize) {
    let mut max_digit = -1;
    let mut max_index = start;

    for i in start..end {
        if digits[i] > max_digit {
            max_digit = digits[i];
            max_index = i;
        }
    }

    (max_digit, max_index)
}
