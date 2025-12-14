//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val lines = Source.fromFile("../input.txt").getLines().toArray
  val (shapes, regions) = parseInput(lines)

  val shapeCellCounts = shapes.map(countCells)
  val shapeBounds = shapes.map(boundingBox)
  val fitCount = regions.count(region => canFitPresents(region, shapeCellCounts, shapeBounds))
  println(s"Part 1: $fitCount")

  // Part 2 is flavor text - no computation needed
  println("Part 2: Merry Christmas!")

case class Shape(cells: Set[(Int, Int)])
case class Region(width: Int, height: Int, shapeCounts: Array[Int])

def parseInput(lines: Array[String]): (Array[Shape], Array[Region]) =
  val shapes = scala.collection.mutable.ArrayBuffer[Shape]()
  val regions = scala.collection.mutable.ArrayBuffer[Region]()

  var index = 0
  while index < lines.length do
    val line = lines(index)

    if line.matches("""\d+:""") then
      val shapeLines = scala.collection.mutable.ArrayBuffer[String]()
      index += 1
      while index < lines.length && lines(index).nonEmpty && !lines(index).matches("""\d+:""") && !lines(index).contains("x") do
        shapeLines += lines(index)
        index += 1

      val cells = for
        (row, rowIndex) <- shapeLines.zipWithIndex
        (char, colIndex) <- row.zipWithIndex
        if char == '#'
      yield (rowIndex, colIndex)

      shapes += Shape(cells.toSet)

    else if line.contains("x") && line.contains(":") then
      val parts = line.split(": ")
      val dimensions = parts(0).split("x")
      val width = dimensions(0).toInt
      val height = dimensions(1).toInt
      val shapeCounts = parts(1).split(" ").map(_.toInt)
      regions += Region(width, height, shapeCounts)
      index += 1

    else
      index += 1

  (shapes.toArray, regions.toArray)

def countCells(shape: Shape): Int = shape.cells.size

def boundingBox(shape: Shape): (Int, Int) =
  if shape.cells.isEmpty then (0, 0)
  else
    val rows = shape.cells.map(_._1)
    val cols = shape.cells.map(_._2)
    (rows.max - rows.min + 1, cols.max - cols.min + 1)

def canFitPresents(region: Region, shapeCellCounts: Array[Int], shapeBounds: Array[(Int, Int)]): Boolean =
  // Check total area constraint
  val totalCellsNeeded = region.shapeCounts.zip(shapeCellCounts).map {
    case (count, cellsPerShape) => count.toLong * cellsPerShape
  }.sum
  val regionArea = region.width.toLong * region.height
  if totalCellsNeeded > regionArea then false
  else
    // Check each shape's bounding box fits in region (allowing rotation)
    region.shapeCounts.zip(shapeBounds).forall { case (count, (shapeWidth, shapeHeight)) =>
      count == 0 ||
        (shapeWidth <= region.width && shapeHeight <= region.height) ||
        (shapeHeight <= region.width && shapeWidth <= region.height)
    }
