//> using scala 3.3
//> using option -deprecation

import scala.io.Source
import scala.collection.mutable

@main def solve(): Unit =
  val grid = Source.fromFile("../input.txt").getLines().toArray

  println(s"Part 1: ${countAccessibleRolls(grid)}")
  println(s"Part 2: ${countTotalRemovable(grid)}")

val directions = List(
  (-1, -1), (-1, 0), (-1, 1),
  (0, -1),           (0, 1),
  (1, -1),  (1, 0),  (1, 1)
)

def countNeighbors(row: Int, col: Int, height: Int, width: Int, isRoll: (Int, Int) => Boolean): Int =
  directions.count { case (dr, dc) =>
    val nr = row + dr
    val nc = col + dc
    nr >= 0 && nr < height && nc >= 0 && nc < width && isRoll(nr, nc)
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

// BFS-based approach: O(n) single pass instead of O(m*n) repeated scans
// When a roll is removed, only its neighbors might become newly accessible
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
      for (dr, dc) <- directions do
        val (nr, nc) = (row + dr, col + dc)
        if inBounds(nr, nc) && grid(nr)(nc) == '@' && !inQueue.contains((nr, nc)) then
          if isAccessible(nr, nc, height, width, isRoll) then
            queue.enqueue((nr, nc))
            inQueue += ((nr, nc))

  totalRemoved
