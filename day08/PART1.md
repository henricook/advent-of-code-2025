# Day 8: Playground

Connect junction boxes with light strings to form circuits.

## Input Format

3D coordinates for junction boxes: `X,Y,Z` (one per line)

## Rules

- Calculate Euclidean distance between all box pairs
- Connect closest pairs first (minimum spanning tree approach)
- Connected boxes form the same circuit
- Boxes already in the same circuit don't need reconnection

## Algorithm

1. Sort all possible connections by distance
2. Connect the 1000 closest pairs
3. Track which boxes belong to which circuit

## Example

Given 20 sample boxes, after connecting the 10 shortest pairs:
- Result: 11 separate circuits
- Circuit sizes: 5, 4, 2, 2, and seven single boxes
- Answer: `5 * 4 * 2 = 40`

## Task

Connect the **1000 closest pairs** of junction boxes from your input, then multiply together the sizes of the **three largest resulting circuits**.
