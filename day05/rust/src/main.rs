use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let lines: Vec<&str> = input.lines().collect();

    let blank_index = lines.iter().position(|l| l.is_empty()).unwrap_or(lines.len());

    let mut ranges: Vec<(i64, i64)> = lines[..blank_index]
        .iter()
        .map(|line| {
            let parts: Vec<i64> = line.split('-').map(|s| s.parse().unwrap()).collect();
            (parts[0], parts[1])
        })
        .collect();

    let ingredients: Vec<i64> = lines[blank_index + 1..]
        .iter()
        .filter(|l| !l.is_empty())
        .map(|l| l.parse().unwrap())
        .collect();

    let merged_ranges = merge_ranges(&mut ranges);
    let fresh_count = ingredients.iter().filter(|&&id| is_in_range(id, &merged_ranges)).count();

    println!("Part 1: {}", fresh_count);

    let total_fresh_ids: i64 = merged_ranges.iter().map(|(start, end)| end - start + 1).sum();
    println!("Part 2: {}", total_fresh_ids);
}

fn merge_ranges(ranges: &mut [(i64, i64)]) -> Vec<(i64, i64)> {
    ranges.sort_by_key(|r| r.0);
    let mut result: Vec<(i64, i64)> = Vec::new();

    for &range in ranges.iter() {
        if result.is_empty() || result.last().unwrap().1 < range.0 - 1 {
            result.push(range);
        } else {
            let last = result.last_mut().unwrap();
            last.1 = last.1.max(range.1);
        }
    }

    result
}

fn is_in_range(id: i64, ranges: &[(i64, i64)]) -> bool {
    let mut low = 0;
    let mut high = ranges.len() as i64 - 1;

    while low <= high {
        let mid = (low + high) / 2;
        let (start, end) = ranges[mid as usize];
        if id < start {
            high = mid - 1;
        } else if id > end {
            low = mid + 1;
        } else {
            return true;
        }
    }

    false
}
