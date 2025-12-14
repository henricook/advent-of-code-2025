# Day 5: Cafeteria

Determine which ingredient IDs are fresh using a database of valid ranges.

## Input Format

1. List of fresh ingredient ID ranges (inclusive, can overlap)
2. Blank line separator
3. List of available ingredient IDs to check

## Rules

- Ranges are inclusive: `3-5` includes IDs 3, 4, and 5
- An ID is fresh if it falls within **any** range
- Multiple ranges can cover the same ID

## Example

**Ranges:** `3-5`, `10-14`, `16-20`, `12-18`

**Available IDs:** `1, 5, 8, 11, 17, 32`

| ID | Status | Reason |
|:--:|:------:|--------|
| 1 | Spoiled | Not in any range |
| 5 | Fresh | In range 3-5 |
| 8 | Spoiled | Not in any range |
| 11 | Fresh | In range 10-14 |
| 17 | Fresh | In ranges 16-20 and 12-18 |
| 32 | Spoiled | Not in any range |

**Result:** 3 available IDs are fresh

## Task

Count how many of the available ingredient IDs are fresh.
