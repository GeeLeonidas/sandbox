import std / [ random, sequtils, sugar, math ]

const
  UnaryOps   = ['P', 'L']
  BinaryOps  = ['+', '-', '*', '/']
  TernaryOps = []
  Terminals  = ['a']

proc concatAllSymbols: seq[char] =
  result = @Terminals
  when UnaryOps.len > 0:
    result = result.concat(@UnaryOps)
  when BinaryOps.len > 0:
    result = result.concat(@BinaryOps)
  when TernaryOps.len > 0:
    result = result.concat(@TernaryOps)

template isOperator(symbol: char): bool =
  (when TernaryOps.len > 0: symbol in TernaryOps else: false) or
  (when BinaryOps.len > 0: symbol in BinaryOps else: false) or
  (when UnaryOps.len > 0: symbol in UnaryOps else: false)

template getMaxParamCount: Natural =
  when TernaryOps.len > 0:
    3
  elif BinaryOps.len > 0:
    2
  elif UnaryOps.len > 0:
    1
  else:
    0

proc initGene(headSize: Positive; maxParamCount = getMaxParamCount()): string =
  let opsAndTerminals = concatAllSymbols()
  for _ in 1..headSize:
    result.add sample(opsAndTerminals)
  let tailSize = headSize * (maxParamCount - 1) + 1
  for _ in 1..tailSize:
    result.add sample(Terminals)

proc evalGene(gene: string, input: varargs[float]): (string, float) =
  assert gene != "", "Shouldn't pass a empty gene!"
  when TernaryOps.len > 0:
    if gene[0] in TernaryOps:
      # TODO: implement ternary logic
      raise newException(ValueError, "Unimplemented ternary operator `" & gene[0] & '`') 
  when BinaryOps.len > 0:
    if gene[0] in BinaryOps:
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
      else:
        raise newException(ValueError, "Unimplemented binary operator `" & gene[0] & '`')
  when UnaryOps.len > 0:
    if gene[0] in UnaryOps:
      let (leftGene, leftRes) = evalGene(gene.substr(1), input)
      case gene[0]
      of 'P':
        return (leftGene, pow(2, leftRes))
      of 'L':
        return (leftGene, log2(leftRes))
      else:
        raise newException(ValueError, "Unimplemented unary operator `" & gene[0] & '`')
  return (gene.substr(1), input[Terminals.find(gene[0])])

proc applyMutation(gene: string, headSize: int; rate = 2 / gene.len): string =
  result = gene
  let opsAndTerminals = concatAllSymbols()
  if opsAndTerminals.len > 1:
    for idx in 0..<headSize:
      if rate >= rand 1.0:
        result[idx] = sample(opsAndTerminals.filterIt(it != result[idx]))
  if Terminals.len > 1:
    for idx in headSize..<gene.len:
      if rate >= rand 1.0:
        result[idx] = sample(@Terminals.filterIt(it != result[idx]))

proc applyInversion(gene: string, headSize: int; rate = 0.1): string =
  result = gene
  if rate >= rand 1.0:
    let
      inversionBegin = rand 0..<headSize-1
      inversionEnd = rand inversionBegin+1..<headSize
    for idx in inversionBegin..inversionEnd:
      let invIdx = inversionEnd - idx + inversionBegin
      result[idx] = gene[invIdx]

proc applyISTransposition(gene: string, headSize: int; rate = 0.1): string =
  result = gene
  if rate >= rand 1.0:
    let
      transposonSize = rand 1..<headSize
      transposonBegin = rand 0..<gene.len-transposonSize
      transposonEnd = transposonBegin + transposonSize - 1
      targetIdx = rand 1..headSize-transposonSize
    var newHead = gene[0..<headSize]
    newHead.insert(gene[transposonBegin..transposonEnd], targetIdx)
    result = newHead[0..<headSize] & gene[headSize..<gene.len]

proc applyRootTransposition(gene: string, headSize: int; rate = 0.1): string =
  result = gene
  if rate >= rand 1.0:
    let
      chosenIdx = rand 0..<headSize
      transposonBegin = block:
        var res = chosenIdx
        for _ in chosenIdx..<headSize:
          if gene[res].isOperator():
            break
          inc res
        if res == headSize:
          return
        res
      transposonEnd = rand transposonBegin..<headSize
      newHead = gene[transposonBegin..transposonEnd] & gene[0..<headSize]
    result = newHead[0..<headSize] & gene[headSize..<gene.len]

proc onePointRecombination(geneOne, geneTwo: string; rate = 0.3): (string, string) =
  result = (geneOne, geneTwo)
  if rate >= rand 1.0:
    let chosenIdx = rand 1..<geneOne.len
    result[0] = geneOne[0..<chosenIdx] & geneTwo[chosenIdx..<geneTwo.len]
    result[1] = geneTwo[0..<chosenIdx] & geneOne[chosenIdx..<geneOne.len]

proc twoPointRecombination(geneOne, geneTwo: string; rate = 0.3): (string, string) =
  result = (geneOne, geneTwo)
  if rate >= rand 1.0:
    let
      segmentBegin = rand 0..<geneOne.len
      segmentEnd = rand segmentBegin..<geneOne.len
    result[0] = geneTwo[0..<segmentBegin] & geneOne[segmentBegin..segmentEnd] & geneTwo[segmentEnd+1..<geneTwo.len]
    result[1] = geneOne[0..<segmentBegin] & geneTwo[segmentBegin..segmentEnd] & geneOne[segmentEnd+1..<geneOne.len]

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
  result = 1000 / (1 + sqrt(sumError) / input.len.float)
  if considerParsimony:
    result += 1e-2 / maxExecSize.float
    # TODO: consider median execution time

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
    EpochCount = 50
    RunCount = 40

  randomize()

  let
    xValues = collect:
      for _ in 1..20:
        rand 0.01..6.0
    yValues = mapIt xValues:
      1 / sqrt(it)

  var
    successCount = 0
    allTimeBestInd = ""
    allTimeBestScore = 0.0

  for run in 1..RunCount:
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

    for epoch in 1..EpochCount:
      sortElite(population, score)
      population = rouletteSelection(population, score)

      for idx in 1..<population.len:
        population[idx] = applyMutation(population[idx], HeadSize)
        population[idx] = applyInversion(population[idx], HeadSize)
        population[idx] = applyISTransposition(population[idx], HeadSize)
        population[idx] = applyRootTransposition(population[idx], HeadSize)
      
      let elite = population[0]
      for idx in 0..<population.len:
        for jdx in idx+1..<population.len:
          let
            (childOne, childTwo) = onePointRecombination(population[idx], population[jdx])
            (parentOne, parentTwo) = if (rand 0..1).bool: (idx, jdx) else: (jdx, idx)
          population[parentOne] = childOne
          population[parentTwo] = childTwo
      population[0] = elite

      score = collect:
        for idx in 0..<population.len:
          fitness(population[idx], xValues, yValues, score[0] > 999.5)
      echo "\nRun ", run, " - Gen ", epoch
      echo "  Avg.  score: ", sum(score) / population.len.float
      echo "  Elite score: ", score[0]
      echo "Best individual"
      echo "  ", population[0]
      let
        chosenIdx = rand 0..<xValues.len
        (_, predicted) = evalGene(population[0], xValues[chosenIdx])
      echo "  Predicted:   ", predicted
      echo "  Expected:    ", yValues[chosenIdx]
    
    if score[0] > allTimeBestScore:
      allTimeBestScore = score[0]
      allTimeBestInd = population[0]
    if score[0] > 999.5:
      inc successCount
  
  echo "\nSummary"
  echo "  Success rate: ", round(100.0 * successCount.float / RunCount).int, '%'
  echo "All-time best individual"
  echo "  ", allTimeBestInd
  echo "  Score:        ", allTimeBestScore
