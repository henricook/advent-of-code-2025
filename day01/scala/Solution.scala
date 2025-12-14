//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val instructions = Source.fromFile("../input.txt").getLines()
    .map(_.trim)
    .filter(_.nonEmpty)
    .toList

  println(s"Part 1: ${countZerosLanding(instructions)}")
  println(s"Part 2: ${countZerosAllClicks(instructions)}")

def countZerosLanding(instructions: List[String]): Int =
  val (_, zeroLandings) = instructions.foldLeft((50, 0)) { case ((dialPosition, count), instruction) =>
    val (direction, moveDistance) = (instruction.head, instruction.tail.toInt)
    val newPosition = direction match
      case 'R' => Math.floorMod(dialPosition + moveDistance, 100)
      case 'L' => Math.floorMod(dialPosition - moveDistance, 100)
    (newPosition, if newPosition == 0 then count + 1 else count)
  }
  zeroLandings

def countZerosAllClicks(instructions: List[String]): Int =
  val (_, totalZeroCrossings) = instructions.foldLeft((50, 0)) { case ((dialPosition, count), instruction) =>
    val (direction, moveDistance) = (instruction.head, instruction.tail.toInt)
    val zeroCrossings = direction match
      case 'R' => (dialPosition + moveDistance) / 100
      case 'L' =>
        if dialPosition == 0 then moveDistance / 100
        else if dialPosition <= moveDistance then (moveDistance - dialPosition) / 100 + 1
        else 0
    val newPosition = direction match
      case 'R' => Math.floorMod(dialPosition + moveDistance, 100)
      case 'L' => Math.floorMod(dialPosition - moveDistance, 100)
    (newPosition, count + zeroCrossings)
  }
  totalZeroCrossings
