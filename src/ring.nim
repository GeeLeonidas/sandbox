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
    discard # Copy
  let newIndex = (ring.start + ring.length) mod ring.capacity
  ring.raw[newIndex] = value
  inc ring.length

proc popFront*[T](ring: RingBuffer[T]): T = 
  when not defined(danger):
    if unlikely(ring.length == 0):
      let exception = new IndexDefect
      exception.msg = "index out of bounds, the container is empty"
      raise exception

proc popBack*[T](ring: RingBuffer[T]): T =
  when not defined(danger):
    if unlikely(ring.length == 0):
      let exception = new IndexDefect
      exception.msg = "index out of bounds, the container is empty"
      raise exception

when isMainModule:
  var test = default(RingBuffer[int])
  echo test.popBack()