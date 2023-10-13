import std / [sequtils, random, sugar, algorithm]

when isMainModule:
  randomize()
  const
    ParamRange = -1e9..1e9
    PopSize    = 1000
  let
    coef = rand ParamRange
    disp = rand ParamRange
    xVal = toSeq 1..100
    data = mapIt xVal:
      let err = it.float * rand -0.01..0.01
      it.float * coef + disp + err
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
