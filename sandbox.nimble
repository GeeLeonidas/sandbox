import std / sequtils

## Package

version     = "0.1.0"
author      = "Guilherme Leoi"
description = "Programming experiments written in Nim"
license     = "MIT"
srcDir      = "src"
binDir      = "bin"
bin         = @["binheap", "dfloat", "ring"]


# Dependencies

requires "nim ^= 2.0.0"