import std / options

type
  Comparable = concept x, y, type T
    x is T
    y is T
    (x < y) is bool
    (x <= y) is bool
    (x == y) is bool
    high(T) is T
    low(T) is T
  BinaryHeap[O: static[bool], T: Comparable] = object 
    raw: ptr UncheckedArray[T]
    capacity: Positive
  MaxHeap[T: Comparable] = BinaryHeap[true, T]
  MinHeap[T: Comparable] = BinaryHeap[false, T]

proc newBinaryHeapOfCap*[O, T](capacity: Positive): BinaryHeap[O, T] =
  result = BinaryHeap[O, T](capacity: capacity)
  result.raw = cast[ptr UncheckedArray[T]](alloc capacity * sizeof(T))
  for i in 0 ..< result.capacity:
    result.raw[i] = when O: low(T) else: high(T)

proc `=destroy`[O, T](x: var BinaryHeap[O, T]) =
  if likely(not x.raw.isNil):
    dealloc x.raw

proc `=copy`[O, T](x: var BinaryHeap[O, T], y: BinaryHeap[O, T]) =
  x = BinaryHeap[O, T](capacity: y.capacity)
  x.raw = cast[ptr UncheckedArray[T]](alloc y.capacity * sizeof(T))
  moveMem(x.raw, y.raw, y.capacity)

proc heapify[O, T](heap: var BinaryHeap[O, T], start: Natural) =
  let
    left  = 2 * start + 1
    right = 2 * start + 2
  
  var fittest = start

  when O: # MaxHeap
    if left < heap.capacity and heap.raw[fittest] < heap.raw[left]:
      fittest = left
    if right < heap.capacity and heap.raw[fittest] < heap.raw[right]:
      fittest = right
  else: # MinHeap
    if left < heap.capacity and heap.raw[fittest] > heap.raw[left]:
      fittest = left
    if right < heap.capacity and heap.raw[fittest] > heap.raw[right]:
      fittest = right
  
  if fittest != start:
    let temp = heap.raw[start]
    heap.raw[start] = heap.raw[fittest]
    heap.raw[fittest] = temp
    heapify(heap, fittest)

proc insert*[O, T](heap: var BinaryHeap[O, T], newItem: T) =
  var
    idx = block:
      var res = 0
      while res < heap.capacity:
        if heap.raw[res] == (when O: low(T) else: high(T)):
          break
        inc res
      when not defined(danger):
        if res == heap.capacity:
          raise newException(IndexDefect, "the binary heap is full")
      res
    parentIdx = (idx - 1) div 2
  heap.raw[idx] = newItem
  while idx > 0:
    heapify(heap, parentIdx)
    idx = parentIdx
    parentIdx = (idx - 1) div 2
  
proc swapHead*[O, T](heap: var BinaryHeap[O, T], newHead: T): T =
  result = heap.raw[0]
  heap.raw[0] = newHead
  heapify(heap, 0)

proc popHead*[O, T](heap: var BinaryHeap[O, T]): T =
  when O: # MaxHeap
    heap.swapHead(low(T))
  else: # MinHeap
    heap.swapHead(high(T))

when isMainModule:
  var heap = newBinaryHeapOfCap[true, int](16)
  heap.insert(4)
  heap.insert(8)
  discard heap.popHead()
  echo heap.popHead()
  