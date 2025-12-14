use std::collections::HashMap;
use std::fs;

struct UnionFind {
    parent: Vec<usize>,
    rank: Vec<usize>,
    component_count: usize,
}

impl UnionFind {
    fn new(size: usize) -> Self {
        UnionFind {
            parent: (0..size).collect(),
            rank: vec![0; size],
            component_count: size,
        }
    }

    fn find(&mut self, x: usize) -> usize {
        if self.parent[x] != x {
            self.parent[x] = self.find(self.parent[x]);
        }
        self.parent[x]
    }

    fn union(&mut self, x: usize, y: usize) -> bool {
        let root_x = self.find(x);
        let root_y = self.find(y);

        if root_x != root_y {
            if self.rank[root_x] < self.rank[root_y] {
                self.parent[root_x] = root_y;
            } else if self.rank[root_x] > self.rank[root_y] {
                self.parent[root_y] = root_x;
            } else {
                self.parent[root_y] = root_x;
                self.rank[root_x] += 1;
            }
            self.component_count -= 1;
            true
        } else {
            false
        }
    }

    fn components(&self) -> usize {
        self.component_count
    }

    fn component_sizes(&mut self) -> HashMap<usize, usize> {
        let mut sizes: HashMap<usize, usize> = HashMap::new();
        for i in 0..self.parent.len() {
            let root = self.find(i);
            *sizes.entry(root).or_insert(0) += 1;
        }
        sizes
    }
}

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let boxes: Vec<(i64, i64, i64)> = input
        .lines()
        .filter(|l| !l.is_empty())
        .map(|line| {
            let parts: Vec<i64> = line.split(',').map(|s| s.parse().unwrap()).collect();
            (parts[0], parts[1], parts[2])
        })
        .collect();

    let edges = build_sorted_edges(&boxes);

    println!("Part 1: {}", find_top_three_component_product(boxes.len(), &edges));
    println!("Part 2: {}", find_last_connection_product(&boxes, &edges));
}

fn build_sorted_edges(boxes: &[(i64, i64, i64)]) -> Vec<(f64, usize, usize)> {
    let num_boxes = boxes.len();
    let mut edges: Vec<(f64, usize, usize)> = Vec::new();

    for i in 0..num_boxes {
        for j in (i + 1)..num_boxes {
            let (x1, y1, z1) = boxes[i];
            let (x2, y2, z2) = boxes[j];
            let dx = (x2 - x1) as f64;
            let dy = (y2 - y1) as f64;
            let dz = (z2 - z1) as f64;
            let distance_squared = dx * dx + dy * dy + dz * dz;
            edges.push((distance_squared, i, j));
        }
    }

    edges.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
    edges
}

fn find_top_three_component_product(num_boxes: usize, sorted_edges: &[(f64, usize, usize)]) -> i64 {
    let mut union_find = UnionFind::new(num_boxes);

    // Connect boxes using the N shortest edges
    for &(_, i, j) in sorted_edges.iter().take(num_boxes) {
        union_find.union(i, j);
    }

    let mut sizes: Vec<i64> = union_find.component_sizes().values().map(|&v| v as i64).collect();
    sizes.sort_by(|a, b| b.cmp(a));

    sizes.iter().take(3).product()
}

fn find_last_connection_product(boxes: &[(i64, i64, i64)], sorted_edges: &[(f64, usize, usize)]) -> i64 {
    let mut union_find = UnionFind::new(boxes.len());
    let mut last_edge_boxes: (usize, usize) = (0, 0);

    for &(_, i, j) in sorted_edges {
        if union_find.components() <= 1 {
            break;
        }
        if union_find.union(i, j) {
            last_edge_boxes = (i, j);
        }
    }

    let (last_i, last_j) = last_edge_boxes;
    boxes[last_i].0 * boxes[last_j].0
}
