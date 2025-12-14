//> using scala 3.3
//> using option -deprecation

import scala.io.Source
import scala.collection.mutable

@main def solve(): Unit =
  val grid = Source.fromFile("../input.txt").getLines().toArray

  println(s"Part 1: ${countAccessibleRolls(grid)}")
  println(s"Part 2: ${countTotalRemovable(grid)}")

val eightDirectionOffsets = List(
  (-1, -1), (-1, 0), (-1, 1),
  (0, -1),           (0, 1),
  (1, -1),  (1, 0),  (1, 1)
)

def countNeighbors(row: Int, col: Int, height: Int, width: Int, isRoll: (Int, Int) => Boolean): Int =
  eightDirectionOffsets.count { case (rowOffset, colOffset) =>
    val neighborRow = row + rowOffset
    val neighborCol = col + colOffset
    neighborRow >= 0 && neighborRow < height && neighborCol >= 0 && neighborCol < width && isRoll(neighborRow, neighborCol)
  }

def isAccessible(row: Int, col: Int, height: Int, width: Int, isRoll: (Int, Int) => Boolean): Boolean =
  countNeighbors(row, col, height, width, isRoll) < 4

def countAccessibleRolls(grid: Array[String]): Int =
  val height = grid.length
  val width = grid(0).length
  val isRoll = (r: Int, c: Int) => grid(r)(c) == '@'

  (for
    row <- 0 until height
    col <- 0 until width
    if grid(row)(col) == '@' && isAccessible(row, col, height, width, isRoll)
  yield 1).sum

def countTotalRemovable(initialGrid: Array[String]): Int =
  val height = initialGrid.length
  val width = initialGrid(0).length
  val grid = initialGrid.map(_.toCharArray)
  val isRoll = (r: Int, c: Int) => grid(r)(c) == '@'
  def inBounds(r: Int, c: Int) = r >= 0 && r < height && c >= 0 && c < width

  val queue = mutable.Queue[(Int, Int)]()
  val inQueue = mutable.Set[(Int, Int)]()

  // Seed queue with all initially accessible rolls
  for
    row <- 0 until height
    col <- 0 until width
    if grid(row)(col) == '@' && isAccessible(row, col, height, width, isRoll)
  do
    queue.enqueue((row, col))
    inQueue += ((row, col))

  var totalRemoved = 0

  while queue.nonEmpty do
    val (row, col) = queue.dequeue()
    inQueue -= ((row, col))

    // Check if still a roll and still accessible (state may have changed)
    if grid(row)(col) == '@' && isAccessible(row, col, height, width, isRoll) then
      grid(row)(col) = '.'
      totalRemoved += 1

      // Check if any neighbors became newly accessible
      for (rowOffset, colOffset) <- eightDirectionOffsets do
        val (neighborRow, neighborCol) = (row + rowOffset, col + colOffset)
        if inBounds(neighborRow, neighborCol) && grid(neighborRow)(neighborCol) == '@' && !inQueue.contains((neighborRow, neighborCol)) then
          if isAccessible(neighborRow, neighborCol, height, width, isRoll) then
            queue.enqueue((neighborRow, neighborCol))
            inQueue += ((neighborRow, neighborCol))

  totalRemoved
