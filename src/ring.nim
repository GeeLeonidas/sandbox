import std / strformat

type RingBuffer*[T] = object
  raw: ptr UncheckedArray[T]
  start, length: Natural
  capacity: Positive

proc newRingBufferOfCap*[T](capacity: Positive): RingBuffer[T] =
  result = RingBuffer[T](capacity: capacity)
  result.raw = cast[ptr UncheckedArray[T]](createU(T, result.capacity))

proc default*[T](_: typedesc[RingBuffer[T]]): RingBuffer[T] =
  newRingBufferOfCap[T](8)

proc `=destroy`*[T](x: var RingBuffer[T]) =
  if likely(not x.raw.isNil):
    dealloc x.raw

proc `=copy`*[T](x: var RingBuffer[T], y: RingBuffer[T]) =
  x = RingBuffer[T](capacity: y.capacity)
  x.raw = cast[ptr UncheckedArray[T]](createU(T, x.capacity))
  moveMem(x.raw, y.raw, y.capacity)

proc `[]`*[T](ring: RingBuffer[T], index: Natural): T =
  when not defined(danger):
    if unlikely(index >= ring.length):
      let exception = new IndexDefect
      exception.msg = fmt"index {index} not in 0 .. {ring.length - 1}"
      raise exception
  result = ring.raw[(ring.start + index) mod ring.capacity]

proc `[]`*[T](ring: RingBuffer[T], index: BackwardsIndex): T =
  ring[ring.length + index.int - 1]

proc grow[T](ring: var RingBuffer[T]) =
  let newRaw = cast[ptr UncheckedArray[T]](createU(T, 2 * ring.capacity))
  for i in 0 ..< ring.length:
    newRaw[i] = ring[i]
  dealloc ring.raw
  ring.raw = newRaw
  ring.start = 0
  ring.capacity *= 2

proc add*[T](ring: var RingBuffer[T], value: T) =
  if unlikely(ring.length >= ring.capacity):
    grow ring
  let newIndex = (ring.start + ring.length) mod ring.capacity
  ring.raw[newIndex] = value
  inc ring.length

proc popFront*[T](ring: var RingBuffer[T]): T = 
  when not defined(danger):
    if unlikely(ring.length == 0):
      let exception = new IndexDefect
      exception.msg = "index out of bounds, the container is empty"
      raise exception
  dec ring.length
  result = ring.raw[ring.start]
  ring.start = (ring.start + 1) mod ring.capacity

proc popBack*[T](ring: var RingBuffer[T]): T =
  when not defined(danger):
    if unlikely(ring.length == 0):
      let exception = new IndexDefect
      exception.msg = "index out of bounds, the container is empty"
      raise exception
  dec ring.length
  result = ring.raw[(ring.start + ring.length) mod ring.capacity]

when isMainModule:
  var test = default(RingBuffer[int])
  for n in 1..15:
    test.add(n)
  echo test.popFront()
  echo test.popBack()
  
  var testTwo = test
  testTwo.add(15)
  echo testTwo[^0]
  echo test[^0]