import std / [tables, monotimes]

type
  Loadable = concept x, type T
    x is T
    loadByKey(T, string) is T
  PaginatedTable[T] = object
    loaded: Table[string, T]
    access: Table[string, MonoTime]
    threshold: range[0..high(int)]

proc initPaginatedTable[T: Loadable]: PaginatedTable[T] =
  result.loaded = initTable[string, T]()
  result.access = initTable[string, MonoTime]()

proc `[]`[T: Loadable](table: PaginatedTable[T], key: string): T =
  if unlikely(not table.loaded.hasKey key):
    if sizeof(table) > table.threshold:
      var
        lowKey: string
        lowAccess = low(MonoTime)
      for key, access in table.access:
        if unlikely(lowAccess == low(MonoTime)):
          lowKey = key
          lowAccess = access
          continue
        if access < lowAccess:
          lowKey = key
          lowAccess = access
      if lowAccess > low(MonoTime):
        table.access.del key
        table.loaded.del key
      else:
        discard # TODO: random key deletion
    table.loaded[key] = T.loadByKey key
  table.access[key] = getMonoTime()
  table.loaded[key]


type TextData = distinct string

proc loadByKey(_: typedesc[TextData], key: string): TextData =
  key.TextData


when isMainModule:
  echo TextData is Loadable
  echo not compiles(initPaginatedTable[int]())
