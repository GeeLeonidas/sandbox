import std / [tables, monotimes, random]

type
  Loadable* = concept x, type T
    x is T
    loadByKey(T, string) is T
  PaginatedTable*[T: Loadable] = object
    loaded: Table[string, tuple[value: T, access: MonoTime]]
    threshold, size: Positive

proc initPaginatedTable*[T: Loadable](threshold = 1000): PaginatedTable[T] =
  result.loaded = initTable[string, tuple[value: T, access: MonoTime]]()
  result.threshold = threshold
  result.size = sizeof result

proc `[]`*[T: Loadable](table: var PaginatedTable[T], selectedKey: string): T =
  if unlikely(not table.loaded.hasKey selectedKey):
    if table.size > table.threshold:
      var
        lowKey: string
        lowAccess = low(MonoTime)
        idxKey: string
        idx = -1
      let randIdx = rand 0..<table.loaded.len
      for key, entry in table.loaded:
        inc idx
        if unlikely(randIdx == idx):
          idxKey = key
        if unlikely(lowAccess == low(MonoTime)):
          lowKey = key
          lowAccess = entry.access
          continue
        if entry.access < lowAccess:
          lowKey = key
          lowAccess = entry.access
      if lowAccess > low(MonoTime):
        table.loaded.del lowKey
      else:
        assert idx >= 0, "Couldn't select an entry from PaginatedTable to delete"
        table.loaded.del idxKey
    let newEntry = (T.loadByKey selectedKey, low(MonoTime))
    if table.size <= table.threshold:
      table.size += sizeof newEntry
    table.loaded[selectedKey] = newEntry
  table.loaded[selectedKey].access = getMonoTime()
  table.loaded[selectedKey].value


type TextData = distinct string

proc loadByKey(_: typedesc[TextData], key: string): TextData =
  echo "Hey!"
  key.TextData

proc `$`(t: TextData): string = t.string


when isMainModule:
  randomize()
  echo TextData is Loadable
  echo not compiles(initPaginatedTable[int]())
  var table = initPaginatedTable[TextData](threshold = 1000)
  echo table["This key doesn't exist!"]
  echo table["This key doesn't exist!"] # But now it does!
  echo table.size
  for i in 1..100_000:
    discard table[$i]
  echo table.size
  echo table["This key doesn't exist!"] # Now it doesn't :(