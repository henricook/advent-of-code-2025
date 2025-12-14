# Day 4: Printing Department

You're in the printing department optimizing forklift operations to access paper rolls.

## Accessibility Rule

A forklift can only access a roll of paper if there are **fewer than 4 rolls** in the 8 adjacent positions (including diagonals).

## Input Format

A grid diagram where:
- `@` = paper roll
- `.` = empty space

## Example

```
..........
.@..@@.@..
.@........
.....@....
.@...@@@..
..@...@...
........@.
.@@...@@..
....@.....
..........
```

Rolls that can be accessed are marked with `x`:
- 13 rolls can be accessed by forklifts

## Task

Count how many paper rolls can be accessed by forklifts (have fewer than 4 neighbors).
