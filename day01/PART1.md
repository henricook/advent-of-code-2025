# Day 1: Secret Entrance

The Elves have discovered project management to prevent their usual Christmas emergency. However, they now face a different crisis: according to resource planning, none of them have time to decorate the North Pole.

You must finish decorating by December 12th. At the secret North Pole entrance, a safe with a dial (numbered 0-99) requires a password. A document provides rotation instructions to open it.

## Rules

- The dial starts pointing at 50
- Rotations follow the format: `L` or `R` (direction) + distance value (clicks)
- Left rotation goes toward lower numbers; right goes toward higher numbers
- The dial wraps around (left from 0 goes to 99; right from 99 goes to 0)

## Example

Given these rotations:
```
L68, L30, R48, L5, R60, L55, L1, L99, R14, L82
```

The dial lands on 0 three times during execution, making the password **3**.

## Task

Analyze the rotations in your attached document. *What's the actual password to open the door?*

The password equals the number of times the dial points at 0 after any rotation.
