# Day 11: Reactor

Analyze data flow through a network of connected devices.

## Input Format

Each line specifies a device and its outputs:
```
device_name: output1 output2 output3
```

Example: `bbb: ddd eee` means device `bbb` connects to `ddd` and `eee`

## Problem

Find the total number of **distinct paths** from device `you` to device `out`.

Data flows in one direction only through the network.

## Example Graph

```
you: bbb ccc
bbb: ddd eee
ccc: ddd eee fff
ddd: ggg
eee: out
fff: out
ggg: out
```

**5 paths from `you` to `out`:**
1. you → bbb → ddd → ggg → out
2. you → bbb → eee → out
3. you → ccc → ddd → ggg → out
4. you → ccc → eee → out
5. you → ccc → fff → out

## Task

Count the total number of **unique paths** from `you` to `out`.
