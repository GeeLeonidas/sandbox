import std / sequtils

## Package

version     = "0.1.0"
author      = "Guilherme Leoi"
description = "Programming experiments written in Nim"
license     = "MIT"
srcDir      = "src"
binDir      = "bin"
bin         = @["binheap", "dfloat", "ring", "paginated", "genetical"]


# Dependencies

requires "nim >= 1.6.0"