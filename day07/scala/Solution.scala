//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val grid = Source.fromFile("../input.txt").getLines().toArray
  val totalSplits = simulateBeam(grid)
  println(s"Part 1: $totalSplits")

  val totalTimelines = countTimelines(grid)
  println(s"Part 2: $totalTimelines")

def simulateBeam(grid: Array[String]): Int =
  val height = grid.length
  val width = if height > 0 then grid(0).length else 0

  val startRow = grid.indexWhere(_.contains('S'))
  val startCol = grid(startRow).indexOf('S')

  val (totalSplitterHits, _) = ((startRow + 1) until height).foldLeft((0, Set(startCol))) {
    case ((splitterHits, activeColumns), row) if activeColumns.nonEmpty =>
      val newHits = activeColumns.count(col =>
        col >= 0 && col < width && grid(row)(col) == '^'
      )

      val nextColumns = activeColumns.flatMap { col =>
        if col >= 0 && col < width && grid(row)(col) == '^' then
          Set(col - 1, col + 1)
        else
          Set(col)
      }.filter(col => col >= 0 && col < width)

      (splitterHits + newHits, nextColumns)
    case (accumulated, _) => accumulated
  }

  totalSplitterHits

def countTimelines(grid: Array[String]): Long =
  val height = grid.length
  val width = if height > 0 then grid(0).length else 0

  val startRow = grid.indexWhere(_.contains('S'))
  val startCol = grid(startRow).indexOf('S')

  // Map from column position to number of distinct timelines passing through it
  val finalTimelineCounts = ((startRow + 1) until height).foldLeft(Map(startCol -> 1L)) {
    case (timelineCountByColumn, row) if timelineCountByColumn.nonEmpty =>
      timelineCountByColumn.toSeq.flatMap { case (col, timelineCount) =>
        if col >= 0 && col < width && grid(row)(col) == '^' then
          Seq((col - 1, timelineCount), (col + 1, timelineCount))
        else
          Seq((col, timelineCount))
      }
      .filter { case (col, _) => col >= 0 && col < width }
      .groupMapReduce(_._1)(_._2)(_ + _)
    case (timelineCountByColumn, _) => timelineCountByColumn
  }

  finalTimelineCounts.values.sum
