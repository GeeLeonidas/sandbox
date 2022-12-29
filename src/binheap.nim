import std / options

type
  Comparable = concept x, y
    (x < y) is bool
    (x <= y) is bool
    (x == y) is bool
  BinaryHeap[O: bool, T: Comparable] = object 
    raw: ptr UncheckedArray[Option[T]]
    capacity: Positive
  MaxHeap[T: Comparable] = BinaryHeap[true, T]
  MinHeap[T: Comparable] = BinaryHeap[false, T]

proc newBinaryHeapOfCap*[O, T](capacity: Positive): BinaryHeap[O, T] =
  result = BinaryHeap[O, T](capacity: capacity)
  result.raw = cast[ptr UncheckedArray[Option[T]]](createU(Option[T], capacity))