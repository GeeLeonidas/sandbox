import std / [sequtils, random, sugar, algorithm, bitops, strformat]

type Chromosome = distinct uint

{.push inline.}
proc value(x: Chromosome): uint = x.uint
proc asInt(x: Chromosome): int = cast[int](x.value)
proc asFloat(x: Chromosome): float = cast[float](x.value)
proc `$`(x: Chromosome): string = &"{$typeof x}({x.uint:#X})"
{.pop.}

proc `~>`(x, y: Chromosome): (Chromosome, Chromosome) =
  const
    ChromosomeBits = 8 * sizeof Chromosome
    CrossoverBits = ChromosomeBits div 3
    MaxBounds = ChromosomeBits - CrossoverBits
  let
    maskInner = block:
      var
        res = 0'u
        count = 0
      while count < CrossoverBits:
        let bitIdx = rand 0..MaxBounds
        if res.testBit(bitIdx):
          continue
        res.flipBit(bitIdx)
        inc count
      res
    maskOuter = not maskInner
    chromoA = (x.value and maskInner) or (y.value and maskOuter)
    chromoB = (y.value and maskInner) or (x.value and maskOuter)
  return (chromoA.Chromosome, chromoB.Chromosome)

type
  Individual[N: static int] = array[N, Chromosome]
  Population[S, N: static int] = array[S, Individual[N]]

proc initIndividual[N: static int]: Individual[N] =
  for i in 0..<N:
    result[i] = (rand uint).Chromosome

proc initPopulation[S, N: static int]: Population[S, N] =
  for i in 0..<S:
    result[i] = initIndividual[N]()

proc nextGeneration[S, N: static int](population: Population[S, N], score: array[S, SomeNumber]): Population[S, N] =
  # Selection phase
  for i in countup(0, S-4, 4):
    let fittest =
      if score[i] > score[i+1] and score[i] > score[i+2] and score[i] > score[i+3]:
        population[i]
      elif score[i+1] > score[i+2] and score[i+1] > score[i+3]:
        population[i+1]
      elif score[i+2] > score[i+3]:
        population[i+2]:
      else:
        population[i+3]
    result[i div 4] = fittest
  # Crossover phase
  for i in countup(0, (S div 4) - 2, 2):
    for j in 0..<N:
      let
        childA, childB = result[i][j] ~> result[i+1][j]
        childC, childD = result[i][j] ~> result[i+1][j]
        childE, childF = result[i][j] ~> result[i+1][j]
        resIdx = (S div 4) + 3*i
      result[resIdx    ][j] = childA
      result[resIdx + 1][j] = childB
      result[resIdx + 2][j] = childC
      result[resIdx + 3][j] = childD
      result[resIdx + 4][j] = childE
      result[resIdx + 5][j] = childF
  # Mutation phase
  for i in 0..<S:
    for j in 0..<N:
      result[i][j].flipBit(rand BitsRange[Chromosome])

when isMainModule:
  randomize()
  const
    ParamRange = -1e9..1e9
    PopSize    = 1000
    ChromNum   = 2
  var population = initPopulation[PopSize, ChromNum]()
  echo population
  #[
  let
    coef = rand ParamRange
    disp = rand ParamRange
    xVal = toSeq 1..100
    data = mapIt xVal:
      let itWithError = it.float * (1.0 + rand -0.01..0.01)
      itWithError * coef + disp
  echo coef, ' ', disp
  var
    bestA = 0.0
    bestB = 0.0
    bestL = 2 * max(ParamRange.a, ParamRange.b)
  for epoch in 1..100:
    let
      population = collect:
        for n in 1..PopSize:
          let
            a = gauss(bestA, bestL)
            b = gauss(bestB, bestL)
            predict = mapIt xVal:
              it.float * a + b
            loss = block:
              let diff = collect:
                for i in 0..<data.len:
                  max(data[i], predict[i]) - min(data[i], predict[i])
              diff.foldl(a + b) / data.len.float
          (a: a, b: b, l: loss)
      sortedPop = population.sortedByIt(it.l)
    if sortedPop[0].l < bestL:
      bestA = sortedPop[0].a
      bestB = sortedPop[0].b
      bestL = sortedPop[0].l
  echo bestL
  echo bestA, ' ', bestB
  ]#
