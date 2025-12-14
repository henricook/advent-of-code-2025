//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val boxes = Source.fromFile("../input.txt").getLines()
    .filter(_.nonEmpty)
    .map { line =>
      val Array(x, y, z) = line.split(",").map(_.toLong)
      (x, y, z)
    }.toArray

  val edges = buildSortedEdges(boxes)

  println(s"Part 1: ${findTopThreeComponentProduct(boxes.length, edges)}")
  println(s"Part 2: ${findLastConnectionProduct(boxes, edges)}")

class UnionFind(size: Int):
  private val parent = Array.tabulate(size)(identity)
  private val rank = Array.fill(size)(0)
  private var componentCount = size

  def find(x: Int): Int =
    if parent(x) != x then
      parent(x) = find(parent(x))
    parent(x)

  def union(x: Int, y: Int): Boolean =
    val rootX = find(x)
    val rootY = find(y)
    if rootX != rootY then
      if rank(rootX) < rank(rootY) then
        parent(rootX) = rootY
      else if rank(rootX) > rank(rootY) then
        parent(rootY) = rootX
      else
        parent(rootY) = rootX
        rank(rootX) += 1
      componentCount -= 1
      true
    else
      false

  def components: Int = componentCount

  def componentSizes: Map[Int, Int] =
    (0 until size).groupBy(find).view.mapValues(_.size).toMap

def buildSortedEdges(boxes: Array[(Long, Long, Long)]): IndexedSeq[(Double, Int, Int)] =
  val numBoxes = boxes.length
  val edges = for
    i <- 0 until numBoxes
    j <- (i + 1) until numBoxes
  yield
    val (x1, y1, z1) = boxes(i)
    val (x2, y2, z2) = boxes(j)
    val dx = (x2 - x1).toDouble
    val dy = (y2 - y1).toDouble
    val dz = (z2 - z1).toDouble
    val distanceSquared = dx*dx + dy*dy + dz*dz
    (distanceSquared, i, j)

  edges.sortBy(_._1)

def findTopThreeComponentProduct(numBoxes: Int, sortedEdges: IndexedSeq[(Double, Int, Int)]): Long =
  val unionFind = UnionFind(numBoxes)

  // Connect boxes using the N shortest edges, where N = number of boxes
  for (_, i, j) <- sortedEdges.take(numBoxes) do
    unionFind.union(i, j)

  val sizes = unionFind.componentSizes.values.toSeq.sorted.reverse.take(3)
  sizes.map(_.toLong).product

def findLastConnectionProduct(boxes: Array[(Long, Long, Long)], sortedEdges: IndexedSeq[(Double, Int, Int)]): Long =
  val unionFind = UnionFind(boxes.length)
  var lastEdgeBoxes: (Int, Int) = (-1, -1)

  for (_, i, j) <- sortedEdges if unionFind.components > 1 do
    if unionFind.union(i, j) then
      lastEdgeBoxes = (i, j)

  val (lastI, lastJ) = lastEdgeBoxes
  boxes(lastI)._1 * boxes(lastJ)._1
