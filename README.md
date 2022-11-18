`resolver` provides utilities for parsing semantic version strings,
and managing dependency versions.

# Dependency Strings

Here are some valid dependency strings:

```
nim >= 1.6.0
nim ^= 1.6.0
nim ~= 1.6.0
nim ~= 1.6.0 and != 1.6.5
```

The following operators are supported:
- `>=` (greater than or equal)
- `<=` (less than or equal)
- `!=` (not equal to)
- `==` (equal to)
- `^=` (optimistically compatible)
- `~=` (pessimistically compatible)
- `and` (boolean AND)
- `or` (boolean OR)

The "and" operator takes precedence over "or."

# Pessimistic vs Optimistic Compatibility

The `~=` and `^=` operators both represent "compatibility," but `~=` is
more strict.

- `~=` requires the major AND minor version numbers to match the rule.
- `^=` requires only the major version number to match the rule.

# Example

```nim
import resolver

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
```
