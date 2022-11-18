## Version rules, and version rule parsing.
## 
## Here are a few examples of valid version rule strings:
## 
## - `>= 1.6.0` any version greater than or equal to 1.6.0
## - `~= 1.6.2 and < 1.6.8` any version that is pessimistically compatible with 1.6.2, and also less than 1.6.8
## - `^= 1.6.2 and < 1.7.2` any version that is optimistically compatible with 1.6.2, and also less than 1.7.2
## - `>= 1.6.0 and != 1.6.2-alpha.2` any version greater than or equal to 1.6.0, except for version 1.6.2-alpha.2
## - `== 1.6.4-alpha.3` exactly version 1.6.4-alpha.3.
## 
## # Syntax
## 
## Version rules have the following syntax:
## 
## ```txt
## <version-rule> ::= <or-rule>
## 
## <or-rule> ::= <and-rule>
##             | <or-rule> "or" <and-rule>
## 
## <and-rule> ::= <base-rule>
##              | <and-rule> "and" <base-rule>
## 
## <base-rule> ::= <version-op> <semver-version>
##               | "(" <version-rule> ")"
## 
## <version-op> ::= "=="
##                | "!="
##                | ">="
##                | "<="
##                | "~="
##                | "^="
## ```
## 
## Note that "and" takes precedence over "or," so these two rules are the same:
## 
## ```txt
## >= 1.0.0 or (>= 0.8.0 and <= 0.8.5)
## >= 1.0.0 or  >= 0.8.0 and <= 0.8.5
## ```
## 
## # Pessimistic vs Optimistic Compatibility
## 
## The `~=` and `^=` operators both represent "compatibility," but `~=` is
## more strict.
## 
## - `~=` requires the major AND minor version numbers to match the rule.
## - `^=` requires only the major version number to match the rule.
## 
runnableExamples:
  let a = parseVersionRule("~= 1.0.0")
  assert     a.matches("1.0.1")
  assert not a.matches("1.1.0")
  assert not a.matches("2.0.0")

  let b = parseVersionRule("^= 1.0.0")
  assert     b.matches("1.0.1")
  assert     b.matches("1.1.0")
  assert not b.matches("2.0.0")

  let c = parseVersionRule(">= 1.0.0")
  assert     c.matches("1.0.1")
  assert     c.matches("1.1.0")
  assert     c.matches("2.0.0")

import types, version, misc
import std/[parseutils, strformat]

proc parseRule(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int
proc parseAnd(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int
proc parseOr(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int
proc parseOperator(input: string, op: var VersionRuleKind, start = 0): int

proc parseVersionRule*(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int =
  ## Parse the given string into a VersionRule. `opts` controls the parser's behavior.
  ## Returns the number of characters parsed.
  result = parseOr(input, rule, start, opts)
  if start + result < len(input) and ConsumeWholeInput in opts:
    raise (start+result).newParseError("Unexpected tokens at end of version rule string")

proc parseVersionRule*(input: string, start = 0, opts = DefaultVersionParseOpts): VersionRule =
  ## Parse the given string into a VersionRule. `opts` controls the parser's behavior.
  discard parseVersionRule(input, result, start, opts)

proc parseRule(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int =
  result += skipWhile(input, Space, start+result)

  var tok = '\0'
  result += parseChar(input, tok, start+result)
  case tok:
  of '(':
    result += parseOr(input, rule, start+result, opts)
    result += skipWhile(input, Space, start+result)
    result += parseChar(input, tok, start+result)
    if tok != ')':
      raise (start+result).newParseError fmt"Expected token ')'"
  of '>', '^', '!', '<', '=', '~':
    result -= 1
    var kind: VersionRuleKind
    var version: Version
    result += parseOperator(input, kind, start+result)
    result += skipWhile(input, Space, start+result)
    result += parseVersion(input, version, start+result, opts - {ConsumeWholeInput})
    rule = VersionRule(kind: kind)
    rule.version = version
  else:
    raise (start+result).newParseError fmt"Unexpected token '{tok}'"

proc parseOperator(input: string, op: var VersionRuleKind, start = 0): int =
  result = skip(input, "==", start)
  if result > 0: op = vrEqual; return
  result = skip(input, ">=", start)
  if result > 0: op = vrGreaterOrEqual; return
  result = skip(input, "<=", start)
  if result > 0: op = vrLesserOrEqual; return
  result = skip(input, "~=", start)
  if result > 0: op = vrBackwardsCompat; return
  result = skip(input, "^=", start)
  if result > 0: op = vrOptimisticBackwardsCompat; return
  result = skip(input, "!=", start)
  if result > 0: op = vrNotEqual; return

  raise start.newParseError "Invalid operator"

proc parseOr(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int =
  result += parseAnd(input, rule, start+result, opts)

  result += skipWhile(input, Space, start+result)
  if skip(input, "or", start+result) == 0: return
  result += 2

  rule = VersionRule(
    kind: vrOr,
    left: rule,
    right: nil
  )

  result += parseOr(input, rule.right, start+result, opts)
  result += skipWhile(input, Space, start+result)


proc parseAnd(input: string, rule: var VersionRule, start = 0, opts = DefaultVersionParseOpts): int =
  result += parseRule(input, rule, start+result, opts)

  result += skipWhile(input, Space, start+result)
  if skip(input, "and", start+result) == 0: return
  result += 3

  rule = VersionRule(
    kind: vrAnd,
    left: rule,
    right: nil
  )

  result += parseAnd(input, rule.right, start+result, opts)
  result += skipWhile(input, Space, start+result)

proc matches*(rule: VersionRule, version: Version): bool =
  ## Returns true if the given version matches the rule.
  if rule.isNil: return true
  return case rule.kind:
  of vrEqual: rule.version ~== version
  of vrNotEqual: not (rule.version ~== version)
  of vrGreaterOrEqual: version >= rule.version
  of vrLesserOrEqual: version <= rule.version
  of vrBackwardsCompat: version ~= rule.version
  of vrOptimisticBackwardsCompat: version ^= rule.version
  of vrAnd: rule.left.matches(version) and rule.right.matches(version)
  of vrOr: rule.left.matches(version) or rule.right.matches(version)

proc matches*(rule: VersionRule, version: string, start=0, opts=DefaultVersionParseOpts): bool =
  ## Returns true if the given version matches the rule.
  rule.matches(parseVersion(version, start, opts))

proc `&`*(left, right: VersionRule): VersionRule =
  ## Creates a VersionRule that is equivalent to `(left) and (right)`.
  VersionRule(
    kind: vrAnd,
    left: left,
    right: right
  )

proc `/`*(left, right: VersionRule): VersionRule =
  ## Creates a VersionRule that is equivalent to `(left) or (right)`.
  VersionRule(
    kind: vrOr,
    left: left,
    right: right
  )

proc `$`*(rule: VersionRule): string =
  case rule.kind:
  of vrEqual:
    result = fmt"== {rule.version}"
  of vrNotEqual:
    result = fmt"!= {rule.version}"
  of vrGreaterOrEqual:
    result = fmt">= {rule.version}"
  of vrLesserOrEqual:
    result = fmt"<= {rule.version}"
  of vrBackwardsCompat:
    result = fmt"~= {rule.version}"
  of vrOptimisticBackwardsCompat:
    result = fmt"^= {rule.version}"
  of vrAnd:
    result = fmt"({rule.left} and {rule.right})"
  of vrOr:
    result = fmt"({rule.left} or {rule.right})"
