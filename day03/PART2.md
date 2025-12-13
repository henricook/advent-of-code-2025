# Day 3: Lobby - Part Two

The escalator needs more joltage. After hitting the "joltage limit safety override" button (and many confirmations), the rules change.

## New Rules

Now you must turn on **exactly twelve batteries** within each bank.

The joltage output is still the number formed by the digits of the batteries turned on, but now it's a 12-digit number.

## Example

```
987654321111111  -> 987654321111 (everything except some 1s at the end)
811111111111119  -> 811111111119 (everything except some 1s)
234234234234278  -> 434234234278 (skip a 2, 3, and 2 near the start)
818181911112111  -> 888911112111 (skip some 1s near the front)
```

Total: 987654321111 + 811111111119 + 434234234278 + 888911112111 = **3121910778619**

## Task

Find the maximum 12-digit joltage from each bank and sum them all.
