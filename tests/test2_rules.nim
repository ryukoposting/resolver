import unittest
import resolver

test "rule '>= 1.0.0 and <= 1.2.0'":
  let rule = parseVersionRule(">=1.0.0 and <=1.2.0")

  check rule.matches("1.0.0")
  check rule.matches("1.1.0")
  check rule.matches("1.2.0")

  check not rule.matches("1.3.0")
  check not rule.matches("1.2.1")
  check not rule.matches("0.3.0")

test "rule '== 1.0.0'":
  let rule = parseVersionRule("==1.0.0")

  check rule.matches("1.0.0")

  check not rule.matches("1.1.0")
  check not rule.matches("1.2.0")
  check not rule.matches("1.3.0")
  check not rule.matches("1.2.1")
  check not rule.matches("0.3.0")

test "rule '~= 1.1.0 or <= 1.0.6'":
  let rule = parseVersionRule("~= 1.1.0 or <= 1.0.6   ")

  check rule.matches("1.1.0")
  check rule.matches("1.1.1")
  check rule.matches("1.1.2")

  check rule.matches("1.0.6")
  check rule.matches("1.0.5")
  check rule.matches("1.0.4")
  check rule.matches("0.9.5")

  check not rule.matches("1.2.0")
  check not rule.matches("1.0.7")
  check not rule.matches("2.0.0")

test "rule '^= 1.1.0 or <= 1.0.6'":
  let rule = parseVersionRule("^= 1.1.0 or <= 1.0.6")

  check rule.matches("1.1.0")
  check rule.matches("1.1.1")
  check rule.matches("1.1.2")
  check rule.matches("1.2.0")

  check rule.matches("1.0.6")
  check rule.matches("1.0.5")
  check rule.matches("1.0.4")
  check rule.matches("0.9.5")

  check not rule.matches("1.0.7")
  check not rule.matches("1.0.7-alpha")
  check not rule.matches("2.0.0")
  check not rule.matches("1.1.0-alpha")

  check rule.matches("1.0.6-alpha")

test "rule '~= 1.1.1 and <= 1.1.7 or >= 1.2.1 and <= 1.2.5'":
  let rule = parseVersionRule("~= 1.1.1 and <= 1.1.7 or >= 1.2.1 and <= 1.3.0")

  check rule.matches("1.1.1")
  check rule.matches("1.1.2-beta")
  check rule.matches("1.1.4")
  check rule.matches("1.1.7")
  check rule.matches("1.1.7-alpha")

  check rule.matches("1.2.1")
  check rule.matches("1.2.5")
  check rule.matches("1.3.0")
  check rule.matches("1.3.0-alpha")

  check not rule.matches("1.1.1-alpha")
  check not rule.matches("1.3.1-alpha")

test "rule '>= 1.0.0 or >= 0.8.0 and <= 0.8.5'":
  let rule = parseVersionRule(">= 1.0.0 or >= 0.8.0 and <= 0.8.5")

  check rule.matches("1.0.0")
  check rule.matches("1.1.0")
  check rule.matches("1.1.1")

  check rule.matches("0.8.0")
  check rule.matches("0.8.5")

  check not rule.matches("0.9.0")

test "rule '^= 1.0'":
  let opts = DefaultVersionParseOpts + {AllowMissingPatch}
  let rule = parseVersionRule("^= 1.0", opts=opts)

  check rule.matches("1.0.0")
  check rule.matches("1.1.0")
  check rule.matches("1.1.1")

  check not rule.matches("0.8.0")
  check not rule.matches("2.0.0")

test "rule '^= 1'":
  let opts = DefaultVersionParseOpts + {AllowMissingMinor}
  let rule = parseVersionRule("^= 1", opts=opts)

  check rule.matches("1.0.0")
  check rule.matches("1.1.0")
  check rule.matches("1.1.1")

  check not rule.matches("0.8.0")
  check not rule.matches("2.0.0")
