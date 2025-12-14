use num_bigint::BigInt;
use std::collections::HashMap;
use std::fs;

fn main() {
    let input = fs::read_to_string("../input.txt").expect("Failed to read input file");
    let lines: Vec<&str> = input.lines().filter(|l| !l.is_empty()).collect();
    let graph = build_graph(&lines);

    let path_count_part1 = count_paths(&graph, "you", "out");
    println!("Part 1: {}", path_count_part1);

    let path_count_part2 = count_paths_with_both(&graph, "svr", "out", "dac", "fft");
    println!("Part 2: {}", path_count_part2);
}

fn build_graph(lines: &[&str]) -> HashMap<String, Vec<String>> {
    lines
        .iter()
        .map(|line| {
            let parts: Vec<&str> = line.split(": ").collect();
            let source = parts[0].to_string();
            let targets: Vec<String> = parts[1].split(' ').map(|s| s.to_string()).collect();
            (source, targets)
        })
        .collect()
}

fn count_paths(graph: &HashMap<String, Vec<String>>, start: &str, end: &str) -> BigInt {
    let mut memo: HashMap<String, BigInt> = HashMap::new();

    fn dfs(
        node: &str,
        end: &str,
        graph: &HashMap<String, Vec<String>>,
        memo: &mut HashMap<String, BigInt>,
    ) -> BigInt {
        if node == end {
            return BigInt::from(1);
        }
        if !graph.contains_key(node) {
            return BigInt::from(0);
        }
        if let Some(cached) = memo.get(node) {
            return cached.clone();
        }

        let result: BigInt = graph[node].iter().map(|next| dfs(next, end, graph, memo)).sum();
        memo.insert(node.to_string(), result.clone());
        result
    }

    dfs(start, end, graph, &mut memo)
}

fn count_paths_with_both(
    graph: &HashMap<String, Vec<String>>,
    start: &str,
    end: &str,
    req1: &str,
    req2: &str,
) -> BigInt {
    let mut memo: HashMap<(String, bool, bool), BigInt> = HashMap::new();

    fn dfs(
        node: &str,
        has_req1: bool,
        has_req2: bool,
        end: &str,
        req1: &str,
        req2: &str,
        graph: &HashMap<String, Vec<String>>,
        memo: &mut HashMap<(String, bool, bool), BigInt>,
    ) -> BigInt {
        let now_has_req1 = has_req1 || node == req1;
        let now_has_req2 = has_req2 || node == req2;

        if node == end {
            return if now_has_req1 && now_has_req2 {
                BigInt::from(1)
            } else {
                BigInt::from(0)
            };
        }
        if !graph.contains_key(node) {
            return BigInt::from(0);
        }

        let key = (node.to_string(), now_has_req1, now_has_req2);
        if let Some(cached) = memo.get(&key) {
            return cached.clone();
        }

        let result: BigInt = graph[node]
            .iter()
            .map(|next| dfs(next, now_has_req1, now_has_req2, end, req1, req2, graph, memo))
            .sum();
        memo.insert(key, result.clone());
        result
    }

    dfs(start, false, false, end, req1, req2, graph, &mut memo)
}
