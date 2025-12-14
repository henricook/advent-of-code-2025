# 🎄 Advent of Code 2025 - Polyglot Solutions

<div align="center">

![Scala](https://img.shields.io/badge/Scala-DC322F?style=for-the-badge&logo=scala&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)
![Zig](https://img.shields.io/badge/Zig-F7A41D?style=for-the-badge&logo=zig&logoColor=white)

**Problem-solving across multiple programming paradigms**

[About](#about) • [Progress](#progress) • [Solutions](#solutions) • [Running](#running) • [Languages](#languages)

</div>

---

## About

This repository contains my solutions to [Advent of Code 2025](https://adventofcode.com/2025), implemented in multiple programming languages for fun

**Language Approach:**
- 🔴 **Scala**: Where my heart lives
- 🟠 **Rust**: Up and coming
- 🟡 **Zig**: Experience of lower level languages is probably important

## Progress

<div align="center">

### 🎯 Completion Status

| Day | Scala | Rust | Zig | Stars | Notes |
|:---:|:-----:|:----:|:---:|:-----:|:------|
| [01](./day01) | ✅ [📄](./day01/scala/Solution.scala) | ✅ [📄](./day01/rust/src/main.rs) | ✅ [📄](./day01/zig/src/main.zig) | ⭐⭐ | Modular arithmetic |
| [02](./day02) | ✅ [📄](./day02/scala/Solution.scala) | ✅ [📄](./day02/rust/src/main.rs) | ✅ [📄](./day02/zig/src/main.zig) | ⭐⭐ | Arithmetic series for pattern sums |
| [03](./day03) | ✅ [📄](./day03/scala/Solution.scala) | ✅ [📄](./day03/rust/src/main.rs) | ✅ [📄](./day03/zig/src/main.zig) | ⭐⭐ | Greedy digit selection |
| [04](./day04) | ✅ [📄](./day04/scala/Solution.scala) | ✅ [📄](./day04/rust/src/main.rs) | ✅ [📄](./day04/zig/src/main.zig) | ⭐⭐ | BFS with neighbor propagation |
| [05](./day05) | ✅ [📄](./day05/scala/Solution.scala) | ✅ [📄](./day05/rust/src/main.rs) | ✅ [📄](./day05/zig/src/main.zig) | ⭐⭐ | Interval merging, binary search |
| [06](./day06) | ✅ [📄](./day06/scala/Solution.scala) | ✅ [📄](./day06/rust/src/main.rs) | ✅ [📄](./day06/zig/src/main.zig) | ⭐⭐ | BigInt, ASCII art parsing |
| [07](./day07) | ✅ [📄](./day07/scala/Solution.scala) | ✅ [📄](./day07/rust/src/main.rs) | ✅ [📄](./day07/zig/src/main.zig) | ⭐⭐ | Beam simulation, timeline counting |
| [08](./day08) | ✅ [📄](./day08/scala/Solution.scala) | ✅ [📄](./day08/rust/src/main.rs) | ✅ [📄](./day08/zig/src/main.zig) | ⭐⭐ | Union-Find with path compression |
| [09](./day09) | ✅ [📄](./day09/scala/Solution.scala) | ✅ [📄](./day09/rust/src/main.rs) | ✅ [📄](./day09/zig/src/main.zig) | ⭐⭐ | Ray casting for point-in-polygon |
| [10](./day10) | ✅ [📄](./day10/scala/Solution.scala) | ✅ [📄](./day10/rust/src/main.rs) | ✅ [📄](./day10/zig/src/main.zig) | ⭐⭐ | Gaussian elimination over GF(2) |
| [11](./day11) | ✅ [📄](./day11/scala/Solution.scala) | ✅ [📄](./day11/rust/src/main.rs) | ✅ [📄](./day11/zig/src/main.zig) | ⭐⭐ | Memoized DFS on DAG |
| [12](./day12) | ✅ [📄](./day12/scala/Solution.scala) | ✅ [📄](./day12/rust/src/main.rs) | ✅ [📄](./day12/zig/src/main.zig) | ⭐⭐ | Bounding box constraint analysis |

**Legend:** ✅ Complete | ⬜ Not Started | 📄 View source

</div>

## Solutions

Each day's solutions are organized in their respective directories with the following structure:

```
dayXX/
├── input.txt     # Shared input for all languages
├── scala/
│   └── Solution.scala
├── rust/
│   ├── Cargo.toml
│   └── src/main.rs
└── zig/
    ├── build.zig
    └── src/main.zig
```

### Highlights

> 🎉 All 12 days complete in all three languages - 24 stars earned!

**Notable implementations:**
- **Day 6**: BigInt arithmetic for ASCII art math problems
- **Day 8**: Union-Find with path compression for 3D clustering
- **Day 10**: GF(2) Gaussian elimination for lights-out puzzles
- **Day 11**: Memoized DFS for counting paths through DAGs

## Running

### Scala Solutions

```bash
cd dayXX/scala
scala Solution.scala
```

### Rust Solutions

```bash
cd dayXX/rust
cargo run --release
```

### Zig Solutions

```bash
cd dayXX/zig
zig build run
```

## Languages

### 🔴 Scala
Leveraging functional programming paradigms, immutable data structures, and powerful pattern matching to write expressive, type-safe solutions.

### 🟠 Rust
Systems programming with zero-cost abstractions, memory safety, and fearless concurrency.

### 🟡 Zig
Exploring low-level control with a modern approach to systems programming, manual memory management, and compile-time execution.

---

<div align="center">

### 📊 Stats

![Languages](https://img.shields.io/github/languages/count/henricook/advent-of-code-2025?style=flat-square)
![Code Size](https://img.shields.io/github/languages/code-size/henricook/advent-of-code-2025?style=flat-square)
![Last Commit](https://img.shields.io/github/last-commit/henricook/advent-of-code-2025?style=flat-square)

**[Advent of Code](https://adventofcode.com/)** is an annual set of Christmas-themed programming challenges that can be solved in any language.

</div>
