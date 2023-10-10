import std / [tables, monotimes, random]

type
  Loadable = concept x, type T
    x is T
    loadByKey(T, string) is T
  PaginatedTable[T: Loadable] = object
    loaded: Table[string, T]
    access: Table[string, MonoTime]
    threshold: range[0..high(int)]

proc initPaginatedTable[T: Loadable]: PaginatedTable[T] =
  result.loaded = initTable[string, T]()
  result.access = initTable[string, MonoTime]()

proc `[]`[T: Loadable](table: PaginatedTable[T], selectedKey: string): T =
  if unlikely(not table.loaded.hasKey selectedKey):
    if sizeof(table) > table.threshold:
      var
        lowKey: string
        lowAccess = low(MonoTime)
        idxKey: string
        idx = -1
      let randIdx = rand 0..<table.access.len
      for key, access in table.access:
        inc idx
        if unlikely(randIdx == idx):
          idxKey = key
        if unlikely(lowAccess == low(MonoTime)):
          lowKey = key
          lowAccess = access
          continue
        if access < lowAccess:
          lowKey = key
          lowAccess = access
      if lowAccess > low(MonoTime):
        table.access.del lowKey
        table.loaded.del lowKey
      else:
        assert idx >= 0, "Couldn't select an entry from PaginatedTable to delete"
        table.access.del idxKey
        table.loaded.del idxKey
    table.loaded[selectedKey] = T.loadByKey selectedKey
  table.access[selectedKey] = getMonoTime()
  table.loaded[selectedKey]


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
