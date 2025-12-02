use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let instructions: Vec<&str> = input.lines().map(|l| l.trim()).filter(|l| !l.is_empty()).collect();

    println!("Part 1: {}", count_zeros_landing(&instructions));
    println!("Part 2: {}", count_zeros_all_clicks(&instructions));
}

fn count_zeros_landing(instructions: &[&str]) -> i32 {
    let mut pos: i32 = 50;
    let mut count = 0;

    for instr in instructions {
        let dir = instr.chars().next().unwrap();
        let dist: i32 = instr[1..].parse().unwrap();

        pos = match dir {
            'R' => pos + dist,
            'L' => pos - dist,
            _ => pos,
        };
        pos = pos.rem_euclid(100);

        if pos == 0 {
            count += 1;
        }
    }
    count
}

fn count_zeros_all_clicks(instructions: &[&str]) -> i32 {
    let mut pos: i32 = 50;
    let mut count = 0;

    for instr in instructions {
        let dir = instr.chars().next().unwrap();
        let dist: i32 = instr[1..].parse().unwrap();

        let crossings = match dir {
            'R' => (pos + dist) / 100,
            'L' => {
                if pos == 0 {
                    dist / 100
                } else if pos <= dist {
                    (dist - pos) / 100 + 1
                } else {
                    0
                }
            }
            _ => 0,
        };

        pos = match dir {
            'R' => pos + dist,
            'L' => pos - dist,
            _ => pos,
        };
        pos = pos.rem_euclid(100);

        count += crossings;
    }
    count
}
