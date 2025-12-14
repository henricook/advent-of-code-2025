//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val digitStrings = Source.fromFile("../input.txt").getLines().filter(_.nonEmpty).toList

  println(s"Part 1: ${sumLargestSelectableNumbers(digitStrings, 2)}")
  println(s"Part 2: ${sumLargestSelectableNumbers(digitStrings, 12)}")

def sumLargestSelectableNumbers(digitStrings: List[String], digitsToSelect: Int): Long =
  digitStrings.map(line => formLargestNumber(line, digitsToSelect)).sum

def formLargestNumber(digitString: String, digitsToSelect: Int): Long =
  val digits = digitString.map(_.asDigit)
  val selectedDigits = selectMaxDigits(digits, digitsToSelect)
  selectedDigits.foldLeft(0L)((number, digit) => number * 10 + digit)

def selectMaxDigits(digits: IndexedSeq[Int], count: Int): List[Int] =
  // Greedy: for each position, pick the largest digit while leaving enough for remaining positions
  val (selected, _) = (0 until count).foldLeft((List.empty[Int], 0)) {
    case ((result, searchStart), position) =>
      val searchEnd = digits.length - (count - position - 1)
      val (maxDigit, maxIndex) = findMaxInRange(digits, searchStart, searchEnd)
      (result :+ maxDigit, maxIndex + 1)
  }
  selected

def findMaxInRange(digits: IndexedSeq[Int], start: Int, end: Int): (Int, Int) =
  val (maxDigit, relativeIndex) = digits.slice(start, end).zipWithIndex.maxBy(_._1)
  (maxDigit, start + relativeIndex)
