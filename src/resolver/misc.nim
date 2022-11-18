import types
import std/strformat

const Space* = {' ', '\t'}

proc newParseError*(pos: int, text: string): ref ParseVersionError =
  ParseVersionError.newException(fmt"At position {pos}: {text}")
