//> using scala 3.3
//> using option -deprecation

import scala.io.Source

@main def solve(): Unit =
  val lines = Source.fromFile("../input.txt").getLines().filter(_.nonEmpty).toArray
  val totalPressesPart1 = lines.map(solveMachinePart1).sum
  println(s"Part 1: $totalPressesPart1")

  val totalPressesPart2 = lines.map(solveMachinePart2).sum
  println(s"Part 2: $totalPressesPart2")

def solveMachinePart1(line: String): Int =
  val targetPattern = """\[([.#]+)\]""".r
  val buttonPattern = """\(([0-9,]+)\)""".r

  val targetMatch = targetPattern.findFirstMatchIn(line).get
  val targetStr = targetMatch.group(1)
  val numLights = targetStr.length
  val target = targetStr.zipWithIndex.filter(_._1 == '#').map(_._2).toSet

  val beforeBraces = line.indexOf('{')
  val buttonSection = if beforeBraces > 0 then line.substring(0, beforeBraces) else line
  val buttons = buttonPattern.findAllMatchIn(buttonSection).map { m =>
    m.group(1).split(",").map(_.toInt).toSet
  }.toArray

  solveGF2(numLights, target, buttons)

// Gaussian elimination over GF(2) - O(n³) instead of O(2^n) brute force
// This is the classic "lights out" puzzle solution using linear algebra over binary field
def solveGF2(numLights: Int, target: Set[Int], buttons: Array[Set[Int]]): Int =
  val numButtons = buttons.length
  if numButtons == 0 then 0
  else
    // Build augmented matrix [A | b] over GF(2)
    // A[i][j] = 1 if button j toggles light i
    // b[i] = 1 if target light i should be on
    val matrix = Array.tabulate(numLights) { light =>
      val row = Array.fill(numButtons + 1)(0)
      for (button, j) <- buttons.zipWithIndex if button.contains(light) do
        row(j) = 1
      row(numButtons) = if target.contains(light) then 1 else 0
      row
    }

    // Gaussian elimination with XOR (addition in GF(2))
    var pivotRow = 0
    val pivotCols = Array.fill(numLights)(-1)

    for col <- 0 until numButtons if pivotRow < numLights do
      // Find a row with 1 in this column
      val pivot = (pivotRow until numLights).find(r => matrix(r)(col) == 1)
      pivot.foreach { p =>
        // Swap rows
        val tmp = matrix(pivotRow)
        matrix(pivotRow) = matrix(p)
        matrix(p) = tmp

        pivotCols(pivotRow) = col

        // Eliminate all other 1s in this column using XOR
        for row <- 0 until numLights if row != pivotRow && matrix(row)(col) == 1 do
          for i <- col to numButtons do
            matrix(row)(i) ^= matrix(pivotRow)(i)

        pivotRow += 1
      }

    // Check for inconsistency: row of form [0 0 ... 0 | 1] means no solution
    val hasInconsistency = (pivotRow until numLights).exists(row => matrix(row)(numButtons) == 1)

    if hasInconsistency then 0
    else
      // Identify free variables (columns without pivots)
      val pivotColSet = pivotCols.filter(_ >= 0).toSet
      val freeVars = (0 until numButtons).filterNot(pivotColSet.contains).toArray

      // Find minimum weight solution by trying all combinations of free variables
      // In GF(2), free variables can only be 0 or 1
      val minPresses = (0 until (1 << freeVars.length)).foldLeft(Int.MaxValue) { (currentMin, mask) =>
        val solution = Array.fill(numButtons)(0)

        // Set free variables according to mask
        for (freeVar, i) <- freeVars.zipWithIndex do
          solution(freeVar) = (mask >> i) & 1

        // Back-substitute to find pivot variables
        for row <- (pivotRow - 1) to 0 by -1 do
          val pivotColumnIndex = pivotCols(row)
          if pivotColumnIndex >= 0 then
            var value = matrix(row)(numButtons)
            for col <- pivotColumnIndex + 1 until numButtons do
              value ^= matrix(row)(col) * solution(col)
            solution(pivotColumnIndex) = value

        val presses = solution.sum
        math.min(currentMin, presses)
      }

      if minPresses == Int.MaxValue then 0 else minPresses

def solveMachinePart2(line: String): Int =
  val buttonPattern = """\(([0-9,]+)\)""".r
  val joltagePattern = """\{([0-9,]+)\}""".r

  val joltageMatch = joltagePattern.findFirstMatchIn(line).get
  val targets = joltageMatch.group(1).split(",").map(_.toInt)
  val numCounters = targets.length

  val beforeBraces = line.indexOf('{')
  val buttonSection = if beforeBraces > 0 then line.substring(0, beforeBraces) else line
  val buttons = buttonPattern.findAllMatchIn(buttonSection).map { m =>
    m.group(1).split(",").map(_.toInt).toSet
  }.toArray

  solveLinearSystem(numCounters, targets, buttons)

// Part 2: Integer linear system (not GF(2)) - buttons add to counters
def solveLinearSystem(numCounters: Int, targets: Array[Int], buttons: Array[Set[Int]]): Int =
  val numButtons = buttons.length

  // Build coefficient matrix A where A[i][j] = 1 if button j affects counter i
  val coeffMatrix = Array.tabulate(numCounters, numButtons) { (i, j) =>
    if buttons(j).contains(i) then 1.0 else 0.0
  }

  // Augmented matrix [A | b]
  val augmented = Array.tabulate(numCounters) { i =>
    coeffMatrix(i) :+ targets(i).toDouble
  }

  // Gaussian elimination with partial pivoting
  var pivotRow = 0
  for col <- 0 until numButtons if pivotRow < numCounters do
    // Find best pivot
    var maxRow = pivotRow
    for row <- pivotRow + 1 until numCounters do
      if math.abs(augmented(row)(col)) > math.abs(augmented(maxRow)(col)) then
        maxRow = row

    if math.abs(augmented(maxRow)(col)) > 1e-10 then
      // Swap rows
      val tmp = augmented(pivotRow)
      augmented(pivotRow) = augmented(maxRow)
      augmented(maxRow) = tmp

      // Eliminate
      val pivot = augmented(pivotRow)(col)
      for i <- 0 to numButtons do
        augmented(pivotRow)(i) /= pivot

      for row <- 0 until numCounters if row != pivotRow do
        val factor = augmented(row)(col)
        for i <- 0 to numButtons do
          augmented(row)(i) -= factor * augmented(pivotRow)(i)

      pivotRow += 1

  // Back-substitute to find a solution
  val solution = Array.fill(numButtons)(0.0)

  // Identify pivot and free variables
  val pivotCols = Array.fill(numCounters)(-1)
  for row <- 0 until pivotRow do
    for col <- 0 until numButtons do
      if math.abs(augmented(row)(col) - 1.0) < 1e-10 then
        if pivotCols(row) < 0 then
          pivotCols(row) = col

  val freeVars = (0 until numButtons).filterNot(pivotCols.contains).toArray

  // For each configuration of free variables, try to find valid solution
  var bestTotal = Int.MaxValue

  def tryFreeVars(idx: Int): Unit =
    if idx == freeVars.length then
      // Compute pivot variable values
      val testSolution = solution.clone()
      for row <- (pivotRow - 1) to 0 by -1 do
        val pivotColumnIndex = pivotCols(row)
        if pivotColumnIndex >= 0 then
          var value = augmented(row)(numButtons)
          for col <- pivotColumnIndex + 1 until numButtons do
            value -= augmented(row)(col) * testSolution(col)
          testSolution(pivotColumnIndex) = value

      // Check if valid (all non-negative integers)
      val allValid = testSolution.forall { v =>
        val rounded = math.round(v).toInt
        math.abs(v - rounded) < 1e-6 && rounded >= 0
      }

      if allValid then
        val total = testSolution.map(v => math.round(v).toInt).sum
        if total < bestTotal then
          bestTotal = total
    else
      val freeVar = freeVars(idx)
      val maxVal = targets.max
      for v <- 0 to maxVal do
        solution(freeVar) = v.toDouble
        tryFreeVars(idx + 1)
      solution(freeVar) = 0.0

  if freeVars.isEmpty then
    for row <- (pivotRow - 1) to 0 by -1 do
      val pivotColumnIndex = pivotCols(row)
      if pivotColumnIndex >= 0 then
        var value = augmented(row)(numButtons)
        for col <- pivotColumnIndex + 1 until numButtons do
          value -= augmented(row)(col) * solution(col)
        solution(pivotColumnIndex) = value

    val allValid = solution.forall { v =>
      val rounded = math.round(v).toInt
      math.abs(v - rounded) < 1e-6 && rounded >= 0
    }

    if allValid then
      solution.map(v => math.round(v).toInt).sum
    else
      0
  else if freeVars.length <= 3 then
    tryFreeVars(0)
    bestTotal
  else
    solveGreedyWithSearch(numCounters, targets, buttons)

def solveGreedyWithSearch(numCounters: Int, targets: Array[Int], buttons: Array[Set[Int]]): Int =
  val numButtons = buttons.length
  val effects = buttons.map { buttonSet =>
    Array.tabulate(numCounters)(i => if buttonSet.contains(i) then 1 else 0)
  }

  val remaining = targets.clone()
  val presses = Array.fill(numButtons)(0)

  var changed = true
  while changed do
    changed = false
    var bestButton = -1
    var bestTimes = 0
    var bestScore = 0.0

    for buttonIdx <- 0 until numButtons do
      val effect = effects(buttonIdx)
      var maxTimes = Int.MaxValue
      for i <- 0 until numCounters do
        if effect(i) > 0 then
          maxTimes = math.min(maxTimes, remaining(i))

      if maxTimes > 0 then
        val progress = effect.sum
        val score = progress.toDouble * maxTimes
        if score > bestScore then
          bestButton = buttonIdx
          bestTimes = maxTimes
          bestScore = score

    if bestButton >= 0 && bestTimes > 0 then
      changed = true
      presses(bestButton) += bestTimes
      for i <- 0 until numCounters do
        remaining(i) -= effects(bestButton)(i) * bestTimes

  if remaining.forall(_ == 0) then
    presses.sum
  else
    0
