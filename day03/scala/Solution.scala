//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val banks = Source.fromFile("../input.txt").getLines().filter(_.nonEmpty).toList

  println(s"Part 1: ${totalMaxJoltage(banks, 2)}")
  println(s"Part 2: ${totalMaxJoltage(banks, 12)}")

def totalMaxJoltage(banks: List[String], digitsToSelect: Int): Long =
  banks.map(bank => maxJoltageForBank(bank, digitsToSelect)).sum

def maxJoltageForBank(bank: String, digitsToSelect: Int): Long =
  val digits = bank.map(_.asDigit)
  val selectedDigits = selectMaxDigits(digits, digitsToSelect)
  selectedDigits.foldLeft(0L)((acc, digit) => acc * 10 + digit)

def selectMaxDigits(digits: IndexedSeq[Int], count: Int): List[Int] =
  // Greedy: for each position, pick the largest digit while leaving enough for remaining positions
  var result = List.empty[Int]
  var startIndex = 0

  for position <- 0 until count do
    // Must leave (count - position - 1) digits after this pick
    val endIndex = digits.length - (count - position - 1)
    val (maxDigit, maxIndex) = findMaxInRange(digits, startIndex, endIndex)
    result = result :+ maxDigit
    startIndex = maxIndex + 1

  result

def findMaxInRange(digits: IndexedSeq[Int], start: Int, end: Int): (Int, Int) =
  var maxDigit = -1
  var maxIndex = start
  for i <- start until end do
    if digits(i) > maxDigit then
      maxDigit = digits(i)
      maxIndex = i
  (maxDigit, maxIndex)
