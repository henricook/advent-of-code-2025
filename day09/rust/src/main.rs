use std::fs;

#[derive(Clone, Copy)]
struct Point {
    x: i64,
    y: i64,
}

struct Rectangle {
    min_x: i64,
    max_x: i64,
    min_y: i64,
    max_y: i64,
}

impl Rectangle {
    fn area(&self) -> i64 {
        (self.max_x - self.min_x + 1) * (self.max_y - self.min_y + 1)
    }

    fn center(&self) -> (i64, i64) {
        ((self.min_x + self.max_x) / 2, (self.min_y + self.max_y) / 2)
    }
}

struct HorizontalSegment {
    y: i64,
    x_min: i64,
    x_max: i64,
}

struct VerticalSegment {
    x: i64,
    y_min: i64,
    y_max: i64,
}

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let tiles: Vec<Point> = input
        .lines()
        .filter(|l| !l.is_empty())
        .map(|line| {
            let parts: Vec<i64> = line.split(',').map(|s| s.parse().unwrap()).collect();
            Point { x: parts[0], y: parts[1] }
        })
        .collect();

    println!("Part 1: {}", find_largest_rectangle(&tiles));
    println!("Part 2: {}", find_largest_rectangle_on_path(&tiles));
}

fn find_largest_rectangle(tiles: &[Point]) -> i64 {
    let mut max_area = 0;
    for i in 0..tiles.len() {
        for j in (i + 1)..tiles.len() {
            let area = (tiles[j].x - tiles[i].x).abs() + 1;
            let height = (tiles[j].y - tiles[i].y).abs() + 1;
            max_area = max_area.max(area * height);
        }
    }
    max_area
}

fn find_largest_rectangle_on_path(tiles: &[Point]) -> i64 {
    let num_tiles = tiles.len();

    let mut horizontal_segments = Vec::new();
    let mut vertical_segments = Vec::new();

    for i in 0..num_tiles {
        let p1 = tiles[i];
        let p2 = tiles[(i + 1) % num_tiles];

        if p1.y == p2.y {
            horizontal_segments.push(HorizontalSegment {
                y: p1.y,
                x_min: p1.x.min(p2.x),
                x_max: p1.x.max(p2.x),
            });
        } else if p1.x == p2.x {
            vertical_segments.push(VerticalSegment {
                x: p1.x,
                y_min: p1.y.min(p2.y),
                y_max: p1.y.max(p2.y),
            });
        }
    }

    let mut max_area = 0;
    for i in 0..num_tiles {
        for j in (i + 1)..num_tiles {
            let p1 = tiles[i];
            let p2 = tiles[j];
            let rect = Rectangle {
                min_x: p1.x.min(p2.x),
                max_x: p1.x.max(p2.x),
                min_y: p1.y.min(p2.y),
                max_y: p1.y.max(p2.y),
            };

            if is_rectangle_valid(&rect, &horizontal_segments, &vertical_segments, tiles) {
                max_area = max_area.max(rect.area());
            }
        }
    }
    max_area
}

fn is_rectangle_valid(
    rect: &Rectangle,
    horizontal_segments: &[HorizontalSegment],
    vertical_segments: &[VerticalSegment],
    polygon: &[Point],
) -> bool {
    // Check if any horizontal segment crosses the interior of the rectangle
    let horizontal_crossing = horizontal_segments.iter().any(|seg| {
        seg.y > rect.min_y
            && seg.y < rect.max_y
            && seg.x_min < rect.max_x
            && seg.x_max > rect.min_x
            && seg.x_min.max(rect.min_x) < seg.x_max.min(rect.max_x)
    });

    // Check if any vertical segment crosses the interior of the rectangle
    let vertical_crossing = vertical_segments.iter().any(|seg| {
        seg.x > rect.min_x
            && seg.x < rect.max_x
            && seg.y_min < rect.max_y
            && seg.y_max > rect.min_y
            && seg.y_min.max(rect.min_y) < seg.y_max.min(rect.max_y)
    });

    // No segment crosses the interior - check if an interior point is inside the polygon
    if horizontal_crossing || vertical_crossing {
        false
    } else {
        let (test_x, test_y) = rect.center();
        is_inside_polygon(test_x, test_y, polygon)
    }
}

fn is_inside_polygon(test_x: i64, test_y: i64, polygon: &[Point]) -> bool {
    // Ray casting algorithm - count crossings to the right
    let mut crossings = 0;
    let num_points = polygon.len();

    for index in 0..num_points {
        let current = polygon[index];
        let previous = polygon[(index + num_points - 1) % num_points];

        // Check if horizontal ray from test point going right crosses this edge
        if (current.y > test_y) != (previous.y > test_y) {
            let intersect_x = current.x
                + (previous.x - current.x) * (test_y - current.y) / (previous.y - current.y);
            if test_x < intersect_x {
                crossings += 1;
            }
        }
    }

    crossings % 2 == 1
}
