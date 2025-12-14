# Day 6: Trash Compactor

Help a young cephalopod with math homework involving vertically-arranged problems.

## Input Format

Math problems arranged vertically and separated by blank columns:
- Numbers stacked vertically
- Operation symbol (`+` or `*`) at the bottom

## Example

```
  1     3       5     6
  2     2       1     4
  3     8       3
        6       8     3
  *     4       7     1
        +       *     4
                      +
```

This represents four problems:
- `123 * 45 * 6 = 33210`
- `328 + 64 + 98 = 490`
- `51 * 387 * 215 = 4243455`
- `64 + 23 + 314 = 401`

## Task

Solve all problems on the worksheet and calculate the **grand total** by adding all individual answers together.

Example grand total: `33210 + 490 + 4243455 + 401 = 4277556`
