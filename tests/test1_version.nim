# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import resolver

const badStrings = [
  "",
  ".",
  "..",
  "0",
  "0.",
  ".0",
  "0.0",
  "0.0.",
  "0..",
  "0..0",
  "-1..0",
]

for badString in badStrings:
  test "parse invalid string '" & badString & "'":
    expect ParseVersionError: discard parseVersion(badString)

test "parse '1.0.0'":
  let version = parseVersion("1.0.0")
  check:
    $version == "1.0.0"
    version.major == 1
    version.minor == 0
    version.patch == 0
    version.preReleaseTags.len == 0
    version.buildMetadata.len == 0

test "parse '1.0.1'":
  let version = parseVersion("1.0.1")
  check:
    $version == "1.0.1"
    version.major == 1
    version.minor == 0
    version.patch == 1
    version.preReleaseTags.len == 0
    version.buildMetadata.len == 0

test "parse '1.0.20'":
  let version = parseVersion("1.0.20")
  check:
    $version == "1.0.20"
    version.major == 1
    version.minor == 0
    version.patch == 20
    version.preReleaseTags.len == 0
    version.buildMetadata.len == 0

test "parse '1.0.20-alpha'":
  let version = parseVersion("1.0.20-alpha")
  check:
    $version == "1.0.20-alpha"
    version.major == 1
    version.minor == 0
    version.patch == 20
    version.preReleaseTags.len == 1
    version.preReleaseTags[0] == "alpha"
    version.buildMetadata.len == 0

test "parse '1.0.20-alpha.4'":
  let version = parseVersion("1.0.20-alpha.4")
  check:
    $version == "1.0.20-alpha.4"
    version.major == 1
    version.minor == 0
    version.patch == 20
    version.preReleaseTags.len == 2
    version.preReleaseTags[0] == "alpha"
    version.preReleaseTags[1] == "4"
    version.buildMetadata.len == 0

test "parse '1.0.20+DEADBEEF'":
  let version = parseVersion("1.0.20+DEADBEEF")
  check:
    $version == "1.0.20+DEADBEEF"
    version.major == 1
    version.minor == 0
    version.patch == 20
    version.preReleaseTags.len == 0
    version.buildMetadata.len == 1
    version.buildMetadata[0] == "DEADBEEF"

test "parse '1.0.20+DEADBEEF.F00'":
  let version = parseVersion("1.0.20+DEADBEEF.F00")
  check:
    $version == "1.0.20+DEADBEEF.F00"
    version.major == 1
    version.minor == 0
    version.patch == 20
    version.preReleaseTags.len == 0
    version.buildMetadata.len == 2
    version.buildMetadata[0] == "DEADBEEF"
    version.buildMetadata[1] == "F00"

test "parse '1.0.20-alpha.55+DEADBEEF.F00'":
  let version = parseVersion("1.0.20-alpha.55+DEADBEEF.F00")
  check:
    $version == "1.0.20-alpha.55+DEADBEEF.F00"
    version.major == 1
    version.minor == 0
    version.patch == 20
    version.preReleaseTags.len == 2
    version.preReleaseTags[0] == "alpha"
    version.preReleaseTags[1] == "55"
    version.buildMetadata.len == 2
    version.buildMetadata[0] == "DEADBEEF"
    version.buildMetadata[1] == "F00"

test "compare '1.0.0' '1.0.1'":
  let
    v1 = parseVersion("1.0.0")
    v2 = parseVersion("1.0.1")
  check v2 > v1 
  check v2 >= v1
  check v2 ~= v1
  check v2 ^= v1

test "compare '1.1.0' '1.0.0'":
  let
    v1 = parseVersion("1.1.0")
    v2 = parseVersion("1.0.0")
  check v2 < v1
  check v2 <= v1
  check not (v1 ~= v2)
  check v1 ^= v2

test "compare '1.0.0-alpha' '1.0.0'":
  let
    v1 = parseVersion("1.0.0-alpha")
    v2 = parseVersion("1.0.0")
  check v2 > v1
  check v2 >= v1
  check v2 ~= v1
  check v2 ^= v1
