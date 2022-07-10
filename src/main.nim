import dfloat

when isMainModule:
  const
    N = 100_000
    A = 33333.33333'df
  var testNum = 0'df

  for i in 1..N:
    testNum += A # I love float imprecision
    if testNum.isDirty: # Just a prototype, not necessary
      clean(testNum) # Mitigates, but doesn't solve the problem

  echo toFloat(A) * N
  echo toFloat(testNum)