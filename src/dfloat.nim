from std/math import round
from std/strutils import parseFloat

type DirtyFloat* = object
  value: float
  dirty: bool

proc `'df`*(n: string): DirtyFloat = DirtyFloat(value: parseFloat(n))

converter toFloat*(dfloat: DirtyFloat): float = dfloat.value

proc isDirty*(self: DirtyFloat): bool = self.dirty

proc clean*(self: DirtyFloat; sigDigits = static[int](7)): DirtyFloat =
  result.value = round(self.value, sigDigits)
  result.dirty = false

proc `+=`*(a: var DirtyFloat, b: DirtyFloat) =
  a.value += b.value
  a.dirty = true

proc `+`*(a, b: DirtyFloat): DirtyFloat =
  result = a
  result += b

proc `-`*(a: DirtyFloat): DirtyFloat =
  result = a
  result.value *= -1

proc `-=`*(a: var DirtyFloat, b: DirtyFloat) =
  a += -b

proc `-`*(a, b: DirtyFloat): DirtyFloat =
  a + (-b)

proc `*=`*(a: var DirtyFloat, b: DirtyFloat) =
  a.value *= b.value
  a.dirty = true

proc `*`*(a, b: DirtyFloat): DirtyFloat =
  result = a
  result *= b

proc `/=`*(a: var DirtyFloat, b: DirtyFloat) =
  a.value /= b.value
  a.dirty = true

proc `/`*(a, b: DirtyFloat): DirtyFloat =
  result = a
  result /= b

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