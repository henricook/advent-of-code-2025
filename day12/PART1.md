# Day 12: Christmas Tree Farm

Fit present shapes into regions beneath Christmas trees.

## Input Format

Two sections:

**1. Present Shapes** - Indexed shapes on grids:
```
Shape 0:    Shape 1:
##          .#
##          ##
```
(`#` = part of shape, `.` = empty)

**2. Regions** - Dimensions and required shapes:
```
12x5: 1 0 1 0 2 2
```
(12 wide, 5 tall, needs: 1 of shape-0, 0 of shape-1, 1 of shape-2, etc.)

## Rules

- Presents can be **rotated and flipped**
- Must align to grid
- Shapes cannot overlap (their `#` portions)
- `.` portions don't block other presents

## Example

Three regions tested:
- Region 1: Can fit all required presents ✓
- Region 2: Can fit all required presents ✓
- Region 3: Cannot fit an extra shape-4 ✗

**Result:** 2 regions can accommodate all presents

## Task

Count how many regions can successfully fit **all their required presents**.
