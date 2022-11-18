import types, misc
import std/[strutils, sequtils, parseutils, strformat, hashes]

proc `$`*(self: Version): string =
  result &= $self.major
  result &= "."
  result &= $self.minor
  result &= "."
  result &= $self.patch

  if self.preReleaseTags.len > 0:
    result &= "-"
    result &= self.preReleaseTags.join(".")

  if self.buildMetadata.len > 0:
    result &= "+"
    result &= self.buildMetadata.join(".")

func hash*(self: Version): Hash =
  result = result !& hash(self.major)
  result = result !& hash(self.minor)
  result = result !& hash(self.patch)
  result = result !& hash('-')
  for tag in self.preReleaseTags:
    result = result !& hash(tag)
    result = result !& hash(0)
  result = result !& hash('+')
  for tag in self.buildMetadata:
    result = result !& hash(tag)
    result = result !& hash(0)
  result = !$result

template checkCmp(arg: untyped): untyped =
  if arg != 0: return arg

func cmp*(a, b: Version): int =
  ## Compare two versions, following [Semver precedence rules](https://semver.org/#spec-item-11).
  ## Note that the `buildMetadata` field is ignored in this comparison!
  result = cmp(a.major, b.major); checkCmp(result)
  result = cmp(a.minor, b.minor); checkCmp(result)
  result = cmp(a.patch, b.patch); checkCmp(result)

  for (atag, btag) in zip(a.preReleaseTags, b.preReleaseTags):
    try:
      result = cmp(parseUInt(atag), parseUInt(btag))
    except ValueError:
      result = cmp(atag, btag)
    checkCmp(result)

  result = -cmp(a.preReleaseTags.len, b.preReleaseTags.len)


func `<`*(a, b: Version): bool =
  ## Compare two versions, following [Semver precedence rules](https://semver.org/#spec-item-11).
  ## Note that the `buildMetadata` field is ignored in this comparison!
  cmp(a, b) < 0

func `>`*(a, b: Version): bool =
  ## Compare two versions, following [Semver precedence rules](https://semver.org/#spec-item-11).
  ## Note that the `buildMetadata` field is ignored in this comparison!
  cmp(a, b) > 0

func `<=`*(a, b: Version): bool =
  ## Compare two versions, following [Semver precedence rules](https://semver.org/#spec-item-11).
  ## Note that the `buildMetadata` field is ignored in this comparison!
  cmp(a, b) <= 0

func `>=`*(a, b: Version): bool =
  ## Compare two versions, following [Semver precedence rules](https://semver.org/#spec-item-11).
  ## Note that the `buildMetadata` field is ignored in this comparison!
  cmp(a, b) >= 0

func `==`*(a, b: Version): bool =
  ## Compare two versions. This considers all parts of the object!
  ## To perform an equality comparison in conformance with Semver, use `~==`.
  return a.major == b.major and 
    a.minor == b.minor and
    a.patch == b.patch and
    a.preReleaseTags.len == b.preReleaseTags.len and
    a.buildMetadata.len == b.buildMetadata.len and
    hash(a) == hash(b)

func `~==`*(a, b: Version): bool =
  ## Compare two versions, following [Semver precedence rules](https://semver.org/#spec-item-11).
  ## Note that the `buildMetadata` field is ignored in this comparison!
  cmp(a, b) == 0

func `~=`*(a, b: Version): bool =
  ## Check to see if `a` is backwards-compatible with `b`. This comparison is
  ## *pessimistic* - in other words, both the major AND minor versions must
  ## match. For an optimistic comparison, use `~>>`.
  runnableExamples:
    let
      a = parseVersion("1.0.0")
      b = parseVersion("1.0.1")
      c = parseVersion("1.1.0")
    assert b ~= a
    assert not (c ~= a)
    assert not (c ~= b)

  return cmp(a, b) >= 0 and a.major == b.major and a.minor == b.minor

func `^=`*(a, b: Version): bool =
  ## Check to see if `a` is backwards-compatible with `b`. This comparison is
  ## *optimistic* - in other words, the major version must match, but the minor
  ## versions can be different. For an optimistic comparison, use `~>>`.
  runnableExamples:
    let
      a = parseVersion("1.0.0")
      b = parseVersion("1.0.1")
      c = parseVersion("1.1.0")
    assert b ^= a
    assert c ^= a
    assert c ^= b

  return cmp(a, b) >= 0 and a.major == b.major

proc expectChar(s: string, c: char, pos: int): int =
  var ch = '\0'
  if parseChar(s, ch, pos) == 0:
    raise pos.newParseError fmt"Expected char '{c}'"
  result = 1

proc parseUint2(input: string, value: var uint, start = 0): int =
  result = parseUint(input, value, start)
  if result == 0:
    raise start.newParseError fmt"Expected a number"

proc parsePreReleaseTag(input: string, value: var string, start = 0): int =
  result = parseWhile(input, value, {'a'..'z', 'A'..'Z', '0'..'9', '-'}, start)
  if result == 0:
    raise start.newParseError "Invalid pre-release tag"

proc parseBuildMetadata(input: string, value: var string, start = 0): int =
  result = parseWhile(input, value, {'a'..'z', 'A'..'Z', '0'..'9', '-'}, start)
  if result == 0:
    raise start.newParseError "Invalid build metadata"

proc parseVersion*(input: string, version: var Version, start = 0, opts = DefaultVersionParseOpts): int =
  ## Parse the input string into a Version.
  if start > high(input):
    raise start.newParseError "Empty string is not a valid version"

  try:
    result += parseUint2(input, version.major, start+result)
  except ValueError:
    raise result.newParseError "Invalid major version"

  var skip = false
  try:
    result += expectChar(input, '.', start+result)
  except ValueError:
    if AllowMissingMinor notin opts:
      raise getCurrentException()
    else:
      skip = true

  if not skip:
    try:
      result += parseUint2(input, version.minor, start+result)
    except ValueError:
      raise result.newParseError "Invalid minor version"

  if not skip:
    try:
      result += expectChar(input, '.', start+result)
    except ValueError:
      if AllowMissingPatch notin opts:
        raise getCurrentException()
      else:
        skip = true

  if not skip:
    try:
      result += parseUint2(input, version.patch, start+result)
    except ValueError:
      raise result.newParseError "Invalid patch version"

  var delim: char
  var dlen = parseChar(input, delim, start+result)

  if delim == '-' and AllowPreReleaseTags in opts:
    delim = '.'
    while dlen > 0 and delim == '.':
      result += dlen
      var id: string
      result += parsePreReleaseTag(input, id, start+result)
      version.preReleaseTags.add id
      delim = '\0'
      dlen = parseChar(input, delim, start+result)

  if delim == '+' and AllowBuildMetadata in opts:
    delim = '.'
    while dlen > 0 and delim == '.':
      result += dlen
      var id: string
      result += parseBuildMetadata(input, id, start+result)
      version.buildMetadata.add id
      delim = '\0'
      dlen = parseChar(input, delim, start+result)

  if ConsumeWholeInput in opts:
    result += skipWhile(input, Space, start+result)
    if start+result < len(input):
      raise result.newParseError "Invalid tokens following version string"

proc parseVersion*(input: string, start = 0, opts = DefaultVersionParseOpts): Version =
  ## Parse the input string into a Version.
  discard parseVersion(input, result, start, opts)

