import std / [tables, monotimes, random]

type
  Loadable = concept x, type T
    x is T
    loadByKey(T, string) is T
  PaginatedTable[T: Loadable] = object
    loaded: Table[string, tuple[value: T, access: MonoTime]]
    threshold: range[0..high(int)]

proc initPaginatedTable[T: Loadable](threshold = 2_097_152): PaginatedTable[T] =
  result.loaded = initTable[string, tuple[value: T, access: MonoTime]]()
  result.threshold = threshold

proc `[]`[T: Loadable](table: var PaginatedTable[T], selectedKey: string): T =
  if unlikely(not table.loaded.hasKey selectedKey):
    if sizeof(table) > table.threshold:
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
    table.loaded[selectedKey] = (T.loadByKey selectedKey, low(MonoTime))
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
  var table = initPaginatedTable[TextData]()
  echo table["This key doesn't exist!"]
  echo table["This key doesn't exist!"] # But now it does!
  echo sizeof(table)
