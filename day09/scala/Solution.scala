//> using scala 3.3
//> using option -deprecation

import scala.io.Source

case class Point(x: Long, y: Long)
case class Rectangle(minX: Long, maxX: Long, minY: Long, maxY: Long):
  def area: Long = (maxX - minX + 1) * (maxY - minY + 1)
  def center: (Long, Long) = ((minX + maxX) / 2, (minY + maxY) / 2)

case class HorizontalSegment(y: Long, xMin: Long, xMax: Long)
case class VerticalSegment(x: Long, yMin: Long, yMax: Long)

@main def solve(): Unit =
  val tiles = Source.fromFile("../input.txt").getLines()
    .filter(_.nonEmpty)
    .map { line =>
      val Array(x, y) = line.split(",").map(_.toLong)
      Point(x, y)
    }.toArray

  val maxArea = findLargestRectangle(tiles)
  println(s"Part 1: $maxArea")

  val maxAreaPart2 = findLargestRectangleOnPath(tiles)
  println(s"Part 2: $maxAreaPart2")

def findLargestRectangle(tiles: Array[Point]): Long =
  (for
    i <- tiles.indices
    j <- (i + 1) until tiles.length
    Point(x1, y1) = tiles(i)
    Point(x2, y2) = tiles(j)
  yield (math.abs(x2 - x1) + 1) * (math.abs(y2 - y1) + 1)).max

def findLargestRectangleOnPath(tiles: Array[Point]): Long =
  // Build horizontal and vertical segments forming the polygon boundary
  val segments = tiles.indices.map { i =>
    val Point(x1, y1) = tiles(i)
    val Point(x2, y2) = tiles((i + 1) % tiles.length)
    (Point(x1, y1), Point(x2, y2))
  }

  val horizontalSegments = segments.collect {
    case (Point(x1, y1), Point(x2, y2)) if y1 == y2 =>
      HorizontalSegment(y1, math.min(x1, x2), math.max(x1, x2))
  }

  val verticalSegments = segments.collect {
    case (Point(x1, y1), Point(x2, y2)) if x1 == x2 =>
      VerticalSegment(x1, math.min(y1, y2), math.max(y1, y2))
  }

  (for
    i <- tiles.indices
    j <- (i + 1) until tiles.length
    Point(x1, y1) = tiles(i)
    Point(x2, y2) = tiles(j)
    rect = Rectangle(math.min(x1, x2), math.max(x1, x2), math.min(y1, y2), math.max(y1, y2))
    if isRectangleValid(rect, horizontalSegments, verticalSegments, tiles)
  yield rect.area).max

def isRectangleValid(
  rect: Rectangle,
  horizontalSegments: IndexedSeq[HorizontalSegment],
  verticalSegments: IndexedSeq[VerticalSegment],
  polygon: Array[Point]
): Boolean =
  // Check if any horizontal segment crosses the interior of the rectangle
  val horizontalCrossing = horizontalSegments.exists { case HorizontalSegment(y, xMin, xMax) =>
    y > rect.minY && y < rect.maxY &&
    xMin < rect.maxX && xMax > rect.minX &&
    math.max(xMin, rect.minX) < math.min(xMax, rect.maxX)
  }

  // Check if any vertical segment crosses the interior of the rectangle
  val verticalCrossing = verticalSegments.exists { case VerticalSegment(x, yMin, yMax) =>
    x > rect.minX && x < rect.maxX &&
    yMin < rect.maxY && yMax > rect.minY &&
    math.max(yMin, rect.minY) < math.min(yMax, rect.maxY)
  }

  // No segment crosses the interior - check if an interior point is inside the polygon
  !horizontalCrossing && !verticalCrossing && {
    val (testX, testY) = rect.center
    isInsidePolygon(testX, testY, polygon)
  }

def isInsidePolygon(testX: Long, testY: Long, polygon: Array[Point]): Boolean =
  // Ray casting algorithm - count crossings to the right
  val crossings = polygon.indices.count { index =>
    val Point(currentX, currentY) = polygon(index)
    val Point(previousX, previousY) = polygon((index + polygon.length - 1) % polygon.length)

    // Check if horizontal ray from test point going right crosses this edge
    (currentY > testY) != (previousY > testY) && {
      val intersectX = currentX + (previousX - currentX) * (testY - currentY) / (previousY - currentY)
      testX < intersectX
    }
  }
  crossings % 2 == 1
