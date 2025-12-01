//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val instructions = Source.fromFile("input.txt").getLines()
    .map(_.trim)
    .filter(_.nonEmpty)
    .toList

  println(s"Part 1: ${countZerosLanding(instructions)}")
  println(s"Part 2: ${countZerosAllClicks(instructions)}")

def countZerosLanding(instructions: List[String]): Int =
  val (_, zeros) = instructions.foldLeft((50, 0)) { case ((pos, count), instr) =>
    val (dir, dist) = (instr.head, instr.tail.toInt)
    val newPos = dir match
      case 'R' => Math.floorMod(pos + dist, 100)
      case 'L' => Math.floorMod(pos - dist, 100)
    (newPos, if newPos == 0 then count + 1 else count)
  }
  zeros

def countZerosAllClicks(instructions: List[String]): Int =
  val (_, zeros) = instructions.foldLeft((50, 0)) { case ((pos, count), instr) =>
    val (dir, dist) = (instr.head, instr.tail.toInt)
    val crossings = dir match
      case 'R' => (pos + dist) / 100
      case 'L' =>
        if pos == 0 then dist / 100
        else if pos <= dist then (dist - pos) / 100 + 1
        else 0
    val newPos = dir match
      case 'R' => Math.floorMod(pos + dist, 100)
      case 'L' => Math.floorMod(pos - dist, 100)
    (newPos, count + crossings)
  }
  zeros
