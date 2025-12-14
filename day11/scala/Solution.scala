//> using scala 3.3
//> using option -deprecation

import scala.io.Source
import scala.collection.mutable

@main def solve(): Unit =
  val lines = Source.fromFile("../input.txt").getLines().filter(_.nonEmpty).toArray
  val graph = buildGraph(lines)

  val pathCountPart1 = countPaths(graph, "you", "out")
  println(s"Part 1: $pathCountPart1")

  val pathCountPart2 = countPathsWithBoth(graph, "svr", "out", "dac", "fft")
  println(s"Part 2: $pathCountPart2")

def buildGraph(lines: Array[String]): Map[String, Array[String]] =
  lines.map { line =>
    val parts = line.split(": ")
    val source = parts(0)
    val targets = parts(1).split(" ")
    source -> targets
  }.toMap

def countPaths(graph: Map[String, Array[String]], start: String, end: String): BigInt =
  val memo = mutable.Map[String, BigInt]()

  def dfs(node: String): BigInt =
    if node == end then BigInt(1)
    else if !graph.contains(node) then BigInt(0)
    else
      memo.getOrElseUpdate(node, {
        graph(node).map(dfs).sum
      })

  dfs(start)

def countPathsWithBoth(graph: Map[String, Array[String]], start: String, end: String, req1: String, req2: String): BigInt =
  // State: (node, visitedReq1, visitedReq2)
  val memo = mutable.Map[(String, Boolean, Boolean), BigInt]()

  def dfs(node: String, hasReq1: Boolean, hasReq2: Boolean): BigInt =
    val nowHasReq1 = hasReq1 || node == req1
    val nowHasReq2 = hasReq2 || node == req2

    if node == end then
      if nowHasReq1 && nowHasReq2 then BigInt(1) else BigInt(0)
    else if !graph.contains(node) then
      BigInt(0)
    else
      memo.getOrElseUpdate((node, nowHasReq1, nowHasReq2), {
        graph(node).map(next => dfs(next, nowHasReq1, nowHasReq2)).sum
      })

  dfs(start, false, false)
