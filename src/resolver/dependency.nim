## Dependencies and dependency parser.
## 
## Dependency strings have the form:
##
## ```txt
## <dep-name> [<version-rule>] [<locator-uri>]
## ```
## 
## Here are some examples of dependency strings:
## - `nim >= 1.6.0`
## - `nim ^= 1.6.0 and != 1.7.2-alpha.0`
## - `nim >= 1.6.6 or == 1.6.2`
## - `nim ~= 1.6.6 https://github.com/nim-lang/nim`
## 

import types, version, versionrule, misc
import std/[parseutils, strutils, uri]

proc parseDependency*(input: string, dep: var Dependency, start = 0, opts = DefaultVersionParseOpts): int =
  ## Parse the input string into a `Dependency`.
  if start > high(input):
    raise start.newParseError "Empty string is not a valid dependency"
  var plen: int
  var nextCh = '\0'

  result += skipWhile(input, Space, start+result)
  plen = parseIdent(input, dep.packageName, start+result)
  if plen == 0:
    raise (start+result).newParseError "Invalid package name"
  result += plen

  dep.versionRule = nil
  plen = skipWhile(input, Space, start+result)
  discard parseChar(input, nextCh, start+result+plen)
  if plen == 0 and result + start < len(input):
    raise (start+result).newParseError "Invalid package name - unexpected character"
  elif plen > 0 and nextCh in VersionRuleStartChars:
    result += parseVersionRule(input, dep.versionRule, start+result, opts - {ConsumeWholeInput})

  if result + start < len(input):
    parseUri(input[start+result..^1], dep.location)

proc parseDependency*(input: string, start = 0, opts = DefaultVersionParseOpts): Dependency =
  ## Parse the input string into a `Dependency`.
  discard parseDependency(input, result, start, opts)

proc matches*(dep: Dependency, package: string, version: Version): bool =
  ## Returns true if the given package-version pair matches the dependency.
  cmpIgnoreStyle(package, dep.packageName) == 0 and
  (dep.versionRule.isNil or dep.versionRule.matches(version))

proc matches*(dep: Dependency, package, version: string, start=0, opts=DefaultVersionParseOpts): bool =
  ## Returns true if the given package-version pair matches the dependency.
  cmpIgnoreStyle(package, dep.packageName) == 0 and
  (dep.versionRule.isNil or dep.versionRule.matches(parseVersion(version, start, opts)))
