`resolver` provides utilities for parsing semantic version strings,
and managing dependency versions.

# Example

```nim
import resolver, std/uri

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

let d = parseDependency("nim ^= 1.6.0")
assert not d.matches("flimflam", "1.6.0")
assert     d.matches("nim", "1.6.0")
assert     d.matches("nim", "1.7.0-alpha.2")
assert not d.matches("nim", "1.6.0-alpha.2")
assert     d.matches("nim", "1.7.0")
assert     d.matches("NIM", "1.7.0")
assert     d.matches("N_I_M", "1.7.0")

let f = parseDependency("nim >= 1.6.4 https://github.com/nim-lang/nim.git")
assert     f.matches("nim", "1.6.4")
assert     f.matches("nim", "1.7.5")
assert not f.matches("nim", "1.6.3")
assert $f.location == "https://github.com/nim-lang/nim.git"
```

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

# Future plans

The existing API is not likely to change. However, this package will eventually
provide more extensive tools for resolving, merging, and ordering dependencies.
