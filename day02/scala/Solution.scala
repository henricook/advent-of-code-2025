//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val input = Source.fromFile("../input.txt").getLines().mkString.trim
  val ranges = parseRanges(input)

  println(s"Part 1: ${sumInvalidIds(ranges)}")
  println(s"Part 2: ${sumRepeatedPatternIds(ranges)}")

case class IdRange(start: Long, end: Long)

def parseRanges(input: String): List[IdRange] =
  input.split(",").map { rangeStr =>
    val parts = rangeStr.split("-")
    IdRange(parts(0).toLong, parts(1).toLong)
  }.toList

def sumInvalidIds(ranges: List[IdRange]): Long =
  ranges.map(sumMirroredNumbersInRange).sum

def sumMirroredNumbersInRange(range: IdRange): Long =
  // Mirrored numbers of 2n digits follow pattern: half * (10^n + 1)
  // e.g., 123123 = 123 * 1001, where 1001 = 10^3 + 1
  val maxDigits = range.end.toString.length
  val maxHalfLength = (maxDigits + 1) / 2

  (1 to maxHalfLength).map { halfLength =>
    val mirrorMultiplier = powerOf10(halfLength) + 1
    val smallestValidHalf = if halfLength == 1 then 1L else powerOf10(halfLength - 1)
    val largestValidHalf = powerOf10(halfLength) - 1

    // Find half-values that produce mirrored numbers within our range
    val smallestHalfInRange = Math.max(smallestValidHalf, ceilDiv(range.start, mirrorMultiplier))
    val largestHalfInRange = Math.min(largestValidHalf, range.end / mirrorMultiplier)

    if smallestHalfInRange <= largestHalfInRange then
      // Sum using arithmetic series: multiplier * n * (first + last) / 2
      val countOfMirroredNumbers = largestHalfInRange - smallestHalfInRange + 1
      mirrorMultiplier * countOfMirroredNumbers * (smallestHalfInRange + largestHalfInRange) / 2
    else
      0L
  }.sum

def powerOf10(exponent: Int): Long = Math.pow(10, exponent).toLong

def ceilDiv(numerator: Long, denominator: Long): Long =
  (numerator + denominator - 1) / denominator

// Part 2: Numbers made of a pattern repeated at least twice (e.g., 123123, 121212, 1111111)

def sumRepeatedPatternIds(ranges: List[IdRange]): Long =
  val maxValue = ranges.map(_.end).max
  val allRepeatedNumbers = generateAllRepeatedPatternNumbers(maxValue).toArray.sorted

  ranges.map { range =>
    allRepeatedNumbers.filter(n => n >= range.start && n <= range.end).sum
  }.sum

def generateAllRepeatedPatternNumbers(maxValue: Long): Set[Long] =
  val maxDigitCount = maxValue.toString.length
  val result = scala.collection.mutable.Set[Long]()

  for
    totalDigitCount <- 2 to maxDigitCount
    patternDigitCount <- 1 until totalDigitCount
    if totalDigitCount % patternDigitCount == 0
    repetitionCount = totalDigitCount / patternDigitCount
    if repetitionCount >= 2
  do
    val repeatMultiplier = computeRepeatMultiplier(patternDigitCount, repetitionCount)
    val smallestPattern = if patternDigitCount == 1 then 1L else powerOf10(patternDigitCount - 1)
    val largestPattern = powerOf10(patternDigitCount) - 1

    for basePattern <- smallestPattern to largestPattern do
      val repeatedNumber = basePattern * repeatMultiplier
      if repeatedNumber <= maxValue then
        result += repeatedNumber

  result.toSet

def computeRepeatMultiplier(patternDigitCount: Int, repetitionCount: Int): Long =
  // For pattern of P digits repeated R times: multiplier = (10^(P*R) - 1) / (10^P - 1)
  // e.g., 12 repeated 3 times: (10^6 - 1) / (10^2 - 1) = 999999 / 99 = 10101
  // So 12 * 10101 = 121212
  val totalDigitCount = patternDigitCount * repetitionCount
  (powerOf10(totalDigitCount) - 1) / (powerOf10(patternDigitCount) - 1)
