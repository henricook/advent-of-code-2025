# Day 9: Movie Theater

Find the largest rectangle using red tiles as opposite corners.

## Input Format

List of coordinates indicating red tile positions: `x,y`

## Problem

Given red tiles on a grid floor, find two red tiles that serve as opposite corners of a rectangle with the **maximum area**.

## Examples

Given various red tile positions:
- Rectangle between `2,5` and `9,7`: area = 24
- Rectangle between `7,1` and `11,7`: area = 35
- Thin rectangle between `7,3` and `2,3`: area = 6
- **Maximum**: Rectangle between `2,5` and `11,1`: area = 50

## Calculation

For opposite corners at `(x1, y1)` and `(x2, y2)`:
```
area = |x2 - x1| * |y2 - y1|
```

## Task

Find the **largest area** of any rectangle that uses two red tiles as opposite corners.
