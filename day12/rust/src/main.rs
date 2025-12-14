use std::collections::HashSet;
use std::fs;

struct Shape {
    cells: HashSet<(i32, i32)>,
}

struct Region {
    width: i32,
    height: i32,
    shape_counts: Vec<i32>,
}

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let lines: Vec<&str> = input.lines().collect();
    let (shapes, regions) = parse_input(&lines);

    let shape_cell_counts: Vec<i32> = shapes.iter().map(count_cells).collect();
    let shape_bounds: Vec<(i32, i32)> = shapes.iter().map(bounding_box).collect();

    let fit_count = regions
        .iter()
        .filter(|region| can_fit_presents(region, &shape_cell_counts, &shape_bounds))
        .count();

    println!("Part 1: {}", fit_count);
    println!("Part 2: Merry Christmas!");
}

fn parse_input(lines: &[&str]) -> (Vec<Shape>, Vec<Region>) {
    let mut shapes = Vec::new();
    let mut regions = Vec::new();
    let mut index = 0;

    while index < lines.len() {
        let line = lines[index];

        if line.chars().next().map_or(false, |c| c.is_ascii_digit())
            && line.ends_with(':')
            && !line.contains('x')
        {
            let mut shape_lines = Vec::new();
            index += 1;

            while index < lines.len()
                && !lines[index].is_empty()
                && !lines[index].contains('x')
                && !(lines[index].chars().next().map_or(false, |c| c.is_ascii_digit())
                    && lines[index].ends_with(':'))
            {
                shape_lines.push(lines[index]);
                index += 1;
            }

            let mut cells = HashSet::new();
            for (row_index, row) in shape_lines.iter().enumerate() {
                for (col_index, ch) in row.chars().enumerate() {
                    if ch == '#' {
                        cells.insert((row_index as i32, col_index as i32));
                    }
                }
            }
            shapes.push(Shape { cells });
        } else if line.contains('x') && line.contains(':') {
            let parts: Vec<&str> = line.split(": ").collect();
            let dimensions: Vec<i32> = parts[0].split('x').map(|s| s.parse().unwrap()).collect();
            let width = dimensions[0];
            let height = dimensions[1];
            let shape_counts: Vec<i32> = parts[1].split(' ').map(|s| s.parse().unwrap()).collect();
            regions.push(Region {
                width,
                height,
                shape_counts,
            });
            index += 1;
        } else {
            index += 1;
        }
    }

    (shapes, regions)
}

fn count_cells(shape: &Shape) -> i32 {
    shape.cells.len() as i32
}

fn bounding_box(shape: &Shape) -> (i32, i32) {
    if shape.cells.is_empty() {
        return (0, 0);
    }

    let rows: Vec<i32> = shape.cells.iter().map(|(r, _)| *r).collect();
    let cols: Vec<i32> = shape.cells.iter().map(|(_, c)| *c).collect();

    let min_row = *rows.iter().min().unwrap();
    let max_row = *rows.iter().max().unwrap();
    let min_col = *cols.iter().min().unwrap();
    let max_col = *cols.iter().max().unwrap();

    (max_row - min_row + 1, max_col - min_col + 1)
}

fn can_fit_presents(
    region: &Region,
    shape_cell_counts: &[i32],
    shape_bounds: &[(i32, i32)],
) -> bool {
    // Check total area constraint
    let total_cells_needed: i64 = region
        .shape_counts
        .iter()
        .zip(shape_cell_counts.iter())
        .map(|(&count, &cells_per_shape)| count as i64 * cells_per_shape as i64)
        .sum();

    let region_area = region.width as i64 * region.height as i64;

    if total_cells_needed > region_area {
        return false;
    }

    // Check each shape's bounding box fits in region (allowing rotation)
    region
        .shape_counts
        .iter()
        .zip(shape_bounds.iter())
        .all(|(&count, &(shape_width, shape_height))| {
            count == 0
                || (shape_width <= region.width && shape_height <= region.height)
                || (shape_height <= region.width && shape_width <= region.height)
        })
}
