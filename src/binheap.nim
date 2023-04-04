import std / options

type
  Comparable = concept x, y
    (x < y) is bool
    (x <= y) is bool
    (x == y) is bool
    high(typeof(x)) is int
    low(typeof(x)) is int
  BinaryHeap[O: bool, T: Comparable] = object 
    raw: ptr UncheckedArray[T]
    capacity: Positive
  MaxHeap[T: Comparable] = BinaryHeap[true, T]
  MinHeap[T: Comparable] = BinaryHeap[false, T]

proc newBinaryHeapOfCap*[O, T](capacity: Positive): BinaryHeap[O, T] =
  result = BinaryHeap[O, T](capacity: capacity)
  result.raw = createU(UncheckedArray[T], capacity)
  for i in 0 ..< result.capacity:
    result.raw[i] = when O: low(T) else: high(T)

proc `=destroy`[O, T](x: var BinaryHeap[O, T]) =
  if likely(not x.raw.isNil):
    dealloc x.raw

proc `=copy`[O, T](x: var BinaryHeap[O, T], y: BinaryHeap[O, T]) =
  x = BinaryHeap[O, T](capacity: y.capacity)
  x.raw = createU(UncheckedArray[T], y.capacity * sizeof(T))
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

proc swapHead*[O, T](heap: var BinaryHeap[O, T], newHead: T): T =
  result = heap.raw[0]
  heap.raw[0] = newHead
  heapify(heap, 0)

proc popHead*[O, T](heap: var BinaryHeap[O, T]): T =
  when O: # MaxHeap
    heap.swapHead(low(T))
  else: # MinHeap
    heap.swapHead(high(T))