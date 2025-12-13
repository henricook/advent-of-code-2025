# Day 3: Lobby

The elevators are offline due to an electrical surge. You need to power the escalator using emergency batteries.

## Battery Banks

Batteries are arranged in banks (one per line). Each digit (1-9) represents a battery's joltage rating.

Within each bank, you must turn on **exactly two batteries**. The joltage produced equals the two-digit number formed by those batteries in order.

Example: Bank `12345`, turning on batteries 2 and 4 produces 24 jolts.

**Note:** Batteries cannot be rearranged - position matters.

## Task

Find the **maximum joltage** each bank can produce, then sum them all.

## Example

```
987654321111111  -> 98 (first two batteries)
811111111111119  -> 89 (batteries showing 8 and 9)
234234234234278  -> 78 (last two batteries)
818181911112111  -> 92 (9 first, then 2)
```

Total: 98 + 89 + 78 + 92 = **357**
