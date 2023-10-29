import std / [ random, sequtils, sugar, math ]

const
  ValidOps  = ['+', '-', '*', '/', 'P', 'L']
  ValidVars = ['a']

proc initGene(headSize: Positive; maxParamCount = 2.Positive): string =
  for _ in 1..headSize:
    result.add sample(@ValidOps.concat(@ValidVars))
  let tailSize = headSize * (maxParamCount - 1) + 1
  for _ in 1..tailSize:
    result.add sample(ValidVars)

proc evalGene(gene: string, input: varargs[float]): (string, float) =
  assert gene != "", "Shouldn't pass a empty gene!"
  if gene[0] in ValidOps:
    let
      (leftGene, leftRes) = evalGene(gene.substr(1), input)
      (rightGene, rightRes) = evalGene(leftGene, input)
    case gene[0]
    of '+':
      return (rightGene, leftRes + rightRes)
    of '-':
      return (rightGene, leftRes - rightRes)
    of '*':
      return (rightGene, leftRes * rightRes)
    of '/':
      return (rightGene, leftRes / rightRes)
    of 'P':
      return (rightGene, pow(leftRes, rightRes))
    of 'L':
      return (rightGene, log(leftRes, rightRes))
    else:
      raise newException(ValueError, "Unimplemented operator `" & gene[0] & '`')
  else:
    return (gene.substr(1), input[ValidVars.find(gene[0])])

proc mutateGene(gene: string, headSize: int; rate = 2 / gene.len): string =
  result = gene
  let opsAndTerminals = @ValidOps.concat(@ValidVars)
  if opsAndTerminals.len > 1:
    for idx in 0..<headSize:
      if rate >= rand 1.0:
        result[idx] = sample(opsAndTerminals.filterIt(it != result[idx]))
  if ValidVars.len > 1:
    for idx in headSize..<gene.len:
      if rate >= rand 1.0:
        result[idx] = sample(@ValidVars.filterIt(it != result[idx]))

# FIXME: score value is too generous
proc fitness(ind: string; input, expected: openArray[float]; considerParsimony = false): float =
  var
    sumError = 0.0
    maxExecSize = 0
  for i in 0..<input.len:
    let (remains, output) = try: evalGene(ind, input[i]) except: return 0
    if output.isNaN or output == Inf or output == NegInf: return 0
    sumError += pow(expected[i] - output, 2)
    let execSize = ind.len - remains.len
    if maxExecSize < execSize:
      maxExecSize = execSize
  result = 1000 / (1 + round(sqrt(sumError)))
  if considerParsimony:
    result += 1e-4 * ind.len.float / maxExecSize.float

proc sortElite(population: var openArray[string], score: var openArray[float]) =
  var eliteIdx = 0
  for idx in 0..<score.len:
    if score[idx] > score[eliteIdx]:
      eliteIdx = idx
  let
    tempInd = population[0]
    tempScore = score[0]
  population[0] = population[eliteIdx]
  score[0] = score[eliteIdx]
  population[eliteIdx] = tempInd
  score[eliteIdx] = tempScore

proc rouletteSelection(population: openArray[string], score: openArray[float]; withElitism = true): seq[string] =
  if withElitism:
    result.add population[0]
  let sumScore = sum score
  var selections = 0
  while selections < population.len:
    var
      idx = 0
      accum = 0.0
      chosen = rand 0.0..sumScore
    block roulette:
      while true:
        while score[idx] == 0:
          inc idx
          if idx == score.len:
            break roulette
        accum += score[idx]
        if accum >= chosen:
          break
        inc idx
      result.add population[min(idx, population.len - 1)]
      inc selections

when isMainModule:
  const
    HeadSize = 14
    SelectiontRange = 100

  randomize()

  let
    xValues = collect:
      for _ in 1..20:
        rand 4.0..100.0
    yValues = mapIt xValues:
      pow(it, 2) + 2 * it

  var
    population = collect:
      for _ in 1..30:
        initGene(HeadSize)
    score = collect:
      for idx in 0..<population.len:
        fitness(population[idx], xValues, yValues)

  while allIt(score, it <= SelectiontRange):
    population = collect:
      for _ in 1..30:
        initGene(HeadSize)
    score = collect:
      for idx in 0..<population.len:
        fitness(population[idx], xValues, yValues)

  for epoch in 1..100:
    sortElite(population, score)
    population = rouletteSelection(population, score)

    for idx in 1..<population.len:
      population[idx] = mutateGene(population[idx], HeadSize)

    score = collect:
      for idx in 0..<population.len:
        fitness(population[idx], xValues, yValues, score[0] > 999.5)
    echo "\nGen ", epoch
    echo "Avg.  score: ", sum(score) / population.len.float
    echo "Elite score: ", score[0]
    echo "\nBest individual"
    echo population[0]
    let
      chosenIdx = rand 0..<xValues.len
      (_, predicted) = evalGene(population[0], xValues[chosenIdx])
    echo "Predicted:   ", predicted
    echo "Expected:    ", yValues[chosenIdx]
