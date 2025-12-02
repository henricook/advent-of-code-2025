# Day 2: Gift Shop - Part Two

The definition of "invalid" has expanded. Now an ID is invalid if it consists of **some sequence of digits repeated at least twice** (not exactly twice).

## New Invalid Examples

- `12341234` - 1234 repeated 2 times
- `123123123` - 123 repeated 3 times
- `1212121212` - 12 repeated 5 times
- `1111111` - 1 repeated 7 times

## Updated Example Results

| Range | Invalid IDs |
|-------|-------------|
| 11-22 | 11, 22 |
| 95-115 | 99, 111 |
| 998-1012 | 999, 1010 |
| 1188511880-1188511890 | 1188511885 |
| 222220-222224 | 222222 |
| 1698522-1698528 | (none) |
| 446443-446449 | 446446 |
| 38593856-38593862 | 38593859 |
| 565653-565659 | 565656 |
| 824824821-824824827 | 824824824 |
| 2121212118-2121212124 | 2121212121 |

**Example sum: 4174379265**

## Task

Find the sum of all invalid IDs using these new rules.
