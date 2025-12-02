use std::collections::HashSet;
use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let ranges = parse_ranges(input.trim());

    println!("Part 1: {}", sum_mirrored_ids(&ranges));
    println!("Part 2: {}", sum_repeated_pattern_ids(&ranges));
}

struct IdRange {
    start: i64,
    end: i64,
}

fn parse_ranges(input: &str) -> Vec<IdRange> {
    input
        .split(',')
        .map(|range_str| {
            let parts: Vec<&str> = range_str.split('-').collect();
            IdRange {
                start: parts[0].parse().unwrap(),
                end: parts[1].parse().unwrap(),
            }
        })
        .collect()
}

// Part 1: Numbers where first half equals second half (e.g., 123123)
fn sum_mirrored_ids(ranges: &[IdRange]) -> i64 {
    ranges.iter().map(|r| sum_mirrored_in_range(r)).sum()
}

fn sum_mirrored_in_range(range: &IdRange) -> i64 {
    let max_digits = digit_count(range.end);
    let max_half_length = (max_digits + 1) / 2;

    (1..=max_half_length)
        .map(|half_length| {
            let mirror_multiplier = power_of_10(half_length) + 1;
            let smallest_valid_half = if half_length == 1 {
                1
            } else {
                power_of_10(half_length - 1)
            };
            let largest_valid_half = power_of_10(half_length) - 1;

            let smallest_half_in_range =
                smallest_valid_half.max(ceil_div(range.start, mirror_multiplier));
            let largest_half_in_range =
                largest_valid_half.min(range.end / mirror_multiplier);

            if smallest_half_in_range <= largest_half_in_range {
                let count = largest_half_in_range - smallest_half_in_range + 1;
                mirror_multiplier * count * (smallest_half_in_range + largest_half_in_range) / 2
            } else {
                0
            }
        })
        .sum()
}

// Part 2: Numbers made of a pattern repeated at least twice (e.g., 123123, 121212, 1111111)
fn sum_repeated_pattern_ids(ranges: &[IdRange]) -> i64 {
    let max_value = ranges.iter().map(|r| r.end).max().unwrap();
    let mut all_repeated_numbers: Vec<i64> =
        generate_all_repeated_pattern_numbers(max_value).into_iter().collect();
    all_repeated_numbers.sort();

    ranges
        .iter()
        .map(|range| {
            all_repeated_numbers
                .iter()
                .filter(|&&n| n >= range.start && n <= range.end)
                .sum::<i64>()
        })
        .sum()
}

fn generate_all_repeated_pattern_numbers(max_value: i64) -> HashSet<i64> {
    let max_digit_count = digit_count(max_value);
    let mut result = HashSet::new();

    for total_digit_count in 2..=max_digit_count {
        for pattern_digit_count in 1..total_digit_count {
            if total_digit_count % pattern_digit_count != 0 {
                continue;
            }
            let repetition_count = total_digit_count / pattern_digit_count;
            if repetition_count < 2 {
                continue;
            }

            let repeat_multiplier =
                compute_repeat_multiplier(pattern_digit_count, repetition_count);
            let smallest_pattern = if pattern_digit_count == 1 {
                1
            } else {
                power_of_10(pattern_digit_count - 1)
            };
            let largest_pattern = power_of_10(pattern_digit_count) - 1;

            for base_pattern in smallest_pattern..=largest_pattern {
                let repeated_number = base_pattern * repeat_multiplier;
                if repeated_number <= max_value {
                    result.insert(repeated_number);
                }
            }
        }
    }

    result
}

fn compute_repeat_multiplier(pattern_digit_count: i32, repetition_count: i32) -> i64 {
    // For pattern of P digits repeated R times: multiplier = (10^(P*R) - 1) / (10^P - 1)
    let total_digit_count = pattern_digit_count * repetition_count;
    (power_of_10(total_digit_count) - 1) / (power_of_10(pattern_digit_count) - 1)
}

fn power_of_10(exponent: i32) -> i64 {
    10_i64.pow(exponent as u32)
}

fn digit_count(n: i64) -> i32 {
    n.to_string().len() as i32
}

fn ceil_div(numerator: i64, denominator: i64) -> i64 {
    (numerator + denominator - 1) / denominator
}
