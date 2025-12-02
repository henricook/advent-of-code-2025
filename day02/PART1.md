# Day 2: Gift Shop

You're helping organize a gift shop's database. The shop has discovered that some of their product IDs are "invalid" - specifically, IDs that consist of a sequence of digits repeated exactly twice.

## Invalid ID Examples

- `55` - the digit 5 repeated twice
- `6464` - the sequence 64 repeated twice
- `123123` - the sequence 123 repeated twice

**Important:** Numbers have no leading zeros, so sequences like `0101` aren't valid IDs.

## Input Format

The puzzle input consists of comma-separated ranges. Each range specifies a first and last ID using a dash separator.

Example: `11-22,95-115,998-1012`

## Task

Find all invalid IDs within the given ranges and return their **sum**.

## Example

For ranges: `11-22,95-115,998-1012,1188511880-1188511890,222220-222224,446443-446449,38593856-38593862`

Invalid IDs found:
- `11-22`: 11, 22
- `95-115`: 99
- `998-1012`: 1010
- `1188511880-1188511890`: 1188511885
- `222220-222224`: 222222
- `446443-446449`: 446446
- `38593856-38593862`: 38593859

**Sum: 1227775554**
