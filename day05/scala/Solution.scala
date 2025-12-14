//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val lines = Source.fromFile("../input.txt").getLines().toArray
  val blankIndex = lines.indexWhere(_.isEmpty)

  val ranges = lines.take(blankIndex).map { line =>
    val Array(start, end) = line.split("-").map(_.toLong)
    (start, end)
  }

  val ingredients = lines.drop(blankIndex + 1).filter(_.nonEmpty).map(_.toLong)

  val mergedRanges = mergeRanges(ranges)
  val freshCount = ingredients.count(id => isInRange(id, mergedRanges))

  println(s"Part 1: $freshCount")

  val totalFreshIds = mergedRanges.map { case (start, end) => end - start + 1 }.sum
  println(s"Part 2: $totalFreshIds")

def mergeRanges(ranges: Array[(Long, Long)]): Array[(Long, Long)] =
  val sorted = ranges.sortBy(_._1)
  val result = scala.collection.mutable.ArrayBuffer[(Long, Long)]()

  for range <- sorted do
    if result.isEmpty || result.last._2 < range._1 - 1 then
      result += range
    else
      val last = result.last
      result(result.length - 1) = (last._1, math.max(last._2, range._2))

  result.toArray

def isInRange(id: Long, ranges: Array[(Long, Long)]): Boolean =
  var low = 0
  var high = ranges.length - 1

  while low <= high do
    val mid = (low + high) / 2
    val (start, end) = ranges(mid)
    if id < start then
      high = mid - 1
    else if id > end then
      low = mid + 1
    else
      return true

  false
