# Day 10: Factory

Determine minimum button presses to configure indicator lights on machines.

## Input Format

Each machine on a single line:
- `[.##.]` - Indicator light diagram (`.` = off, `#` = on)
- `(1,3)` - Button schematics (which lights each button toggles)
- `{3,5,4,7}` - Joltage requirements (ignore these)

## Rules

- All lights start **off**
- Each button **toggles** specific lights (on→off or off→on)
- Buttons can be pressed any non-negative number of times
- Goal: Match the target configuration

## Example

Machine: `[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}`

- Target: lights 1 and 2 on, lights 0 and 3 off
- Solution: Press `(0,2)` once + `(0,1)` once = **2 presses**

Three example machines need 2, 3, and 2 presses = **7 total**

## Task

Find the **fewest total button presses** required to correctly configure all machines.
