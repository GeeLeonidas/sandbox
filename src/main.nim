import dfloat

when isMainModule:
  const
    N = 10_000
    A = 3.333'df
  var testNum = 0'df

  for i in 1..N:
    testNum += A # I love float imprecision

  let
    rightValue = toFloat(A) * N
    obtainedValue = toFloat(clean testNum)
    dirtyValue = toFloat(testNum)

  echo rightValue
  echo obtainedValue
  echo rightValue == obtainedValue
  echo dirtyValue
  echo rightValue == dirtyValue