//> using scala 3.3
//> using option -deprecation

import scala.io.Source

// Input contains math problems arranged as ASCII art, separated by blank columns.
// Each problem block contains multi-digit numbers and an operation (+/*).
// Part 1: Numbers are written horizontally (one per row, left-to-right)
// Part 2: Numbers are written vertically (one per column, read right-to-left for cephalopod math)

@main def solve(): Unit =
  val lines = Source.fromFile("../input.txt").getLines().filter(_.nonEmpty).toArray
  val maxWidth = lines.map(_.length).max
  val paddedLines = lines.map(_.padTo(maxWidth, ' '))

  val problemsPart1 = extractProblems(paddedLines, parseRowWise)
  val grandTotalPart1 = problemsPart1.map(evaluateProblem).sum
  println(s"Part 1: $grandTotalPart1")

  val problemsPart2 = extractProblems(paddedLines, parseColumnWise)
  val grandTotalPart2 = problemsPart2.map(evaluateProblem).sum
  println(s"Part 2: $grandTotalPart2")

case class Problem(numbers: List[BigInt], operation: Char)

def extractProblems(
    lines: Array[String],
    parser: (Array[String], Int, Int) => Problem
): List[Problem] =
  val width = lines.head.length

  // Find column ranges for each problem block using functional iteration
  val columnRanges = (0 until width)
    .foldLeft((List.empty[(Int, Int)], Option.empty[Int])) { case ((ranges, blockStart), col) =>
      val isBlank = isBlankColumn(lines, col)
      (blockStart, isBlank) match
        case (None, false) => (ranges, Some(col))                    // Start of new block
        case (Some(start), true) => ((start, col) :: ranges, None)   // End of block
        case _ => (ranges, blockStart)                               // Continue current state
    } match
      case (ranges, Some(start)) => (start, width) :: ranges         // Handle trailing block
      case (ranges, None) => ranges

  columnRanges.reverse.map { case (start, end) => parser(lines, start, end) }

def isBlankColumn(lines: Array[String], col: Int): Boolean =
  lines.forall(line => col >= line.length || line(col) == ' ')

// Part 1: Read each row within the column range as a number (horizontally)
def parseRowWise(lines: Array[String], startCol: Int, endCol: Int): Problem =
  val (numbers, operation) = lines.foldLeft((List.empty[BigInt], '+')) { case ((nums, op), line) =>
    val rowSlice = line.substring(startCol, math.min(endCol, line.length))
    val digits = rowSlice.filter(_.isDigit)
    val foundOp = rowSlice.find(c => c == '+' || c == '*')

    val newNums = if digits.nonEmpty then BigInt(digits) :: nums else nums
    val newOp = foundOp.getOrElse(op)
    (newNums, newOp)
  }
  Problem(numbers.reverse, operation)

// Part 2: Cephalopod math reads numbers vertically - each column is a number (digits top-to-bottom).
// Columns are processed right-to-left because cephalopods read from right to left.
def parseColumnWise(lines: Array[String], startCol: Int, endCol: Int): Problem =
  val (numbers, operation) = ((endCol - 1) to startCol by -1).foldLeft((List.empty[BigInt], '+')) {
    case ((nums, op), col) =>
      val columnChars = lines.map(line => if col < line.length then line(col) else ' ')
      val digits = columnChars.filter(_.isDigit)
      val foundOp = columnChars.find(c => c == '+' || c == '*')

      val newNums = if digits.nonEmpty then BigInt(digits.mkString) :: nums else nums
      val newOp = foundOp.getOrElse(op)
      (newNums, newOp)
  }
  Problem(numbers.reverse, operation)

def evaluateProblem(problem: Problem): BigInt =
  problem.operation match
    case '+' => problem.numbers.sum
    case '*' => problem.numbers.product
