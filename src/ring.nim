import std / strformat

type RingBuffer*[T] = object
  raw: ptr UncheckedArray[T]
  start, length: Natural
  capacity: Positive

proc default*[T](_: typedesc[RingBuffer[T]]): RingBuffer[T] =
  result = RingBuffer[T](capacity: 16)
  result.raw = cast[ptr UncheckedArray[T]](createU(T, result.capacity))

proc `=destroy`*[T](x: var RingBuffer[T]) =
  if likely(not x.raw.isNil):
    dealloc x.raw

proc add*[T](ring: var RingBuffer[T], value: T) =
  if unlikely(ring.length >= ring.capacity):
    return # Copy
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

proc `[]`*[T](ring: RingBuffer[T], index: Natural): T =
  when not defined(danger):
    if unlikely(index >= ring.length):
      let exception = new IndexDefect
      exception.msg = fmt"index {index} not in 0 .. {ring.length - 1}"
      raise exception
  result = ring.raw[(ring.start + index) mod ring.capacity]

when isMainModule:
  var test = default(RingBuffer[int])
  for i in 1..10:
    test.add(i)
  echo test.popFront()
  echo test.popBack()
  echo test[0]