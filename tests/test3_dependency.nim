import unittest, uri
import resolver

test "dependency 'nim >= 1.6.8'":
  let dep = parseDependency("nim >= 1.6.8")

  check dep.matches("nim", "1.6.8")
  check dep.matches("nim", "1.6.9")
  check dep.matches("nim", "1.7.9")
  check dep.matches("nim", "2.7.9")
  check dep.matches("Nim", "2.7.9")
  check dep.matches("NIM", "2.7.9")
  check dep.matches("N_i_M__", "2.7.9")

  check not dep.matches("nim", "1.6.7")
  check not dep.matches("nim", "1.5.8")
  check not dep.matches("nim", "0.6.8")
  check not dep.matches("flim", "1.6.8")

test "dependency 'nim ^= 1.6.8 and <= 1.7.2-alpha.2'":
  let dep = parseDependency("nim ^= 1.6.8 and <= 1.7.2-alpha.2")

  check dep.matches("nim", "1.6.8")
  check dep.matches("nim", "1.6.9")
  check dep.matches("nim", "1.7.0")
  check dep.matches("nim", "1.7.0-alpha")
  check dep.matches("nim", "1.7.0-beta")
  check dep.matches("nim", "1.7.2-alpha.2")
  check dep.matches("nim", "1.7.2-alpha.1")

  check dep.matches("Nim", "1.6.8")
  check dep.matches("Nim", "1.6.9")
  check dep.matches("Nim", "1.7.0")
  check dep.matches("Nim", "1.7.0-alpha")
  check dep.matches("Nim", "1.7.0-beta")
  check dep.matches("Nim", "1.7.2-alpha.2")
  check dep.matches("Nim", "1.7.2-alpha.1")

  check not dep.matches("nim", "1.6.8-beta")
  check not dep.matches("nim", "1.7.2-alpha.3")

  check not dep.matches("nim", "1.6.7")
  check not dep.matches("nim", "1.5.8")
  check not dep.matches("nim", "0.6.8")
  check not dep.matches("flim", "1.6.8")

  check not dep.matches("nim", "1.7.9")
  check not dep.matches("Nim", "1.6.7")
  check not dep.matches("NIM", "1.6.7")
  check not dep.matches("N_i_M__", "1.6.7")

test "dependency 'nim >= 1.6.4 ssh://git@github.com/nim-lang/Nim.git'":
  let dep = parseDependency("nim >= 1.6.4 ssh://git@github.com/nim-lang/Nim.git")

  check dep.matches("nim", "1.6.4")
  check dep.matches("nim", "1.6.8")
  check dep.matches("nim", "1.7.8")
  check dep.matches("nim", "2.7.8")

  check dep.location.scheme == "ssh"
  check dep.location.username == "git"
  check dep.location.password == ""
  check dep.location.hostname == "github.com"
  check dep.location.path == "/nim-lang/Nim.git"
  check dep.location.anchor == ""
  check dep.location.query == ""
  check dep.location.port == ""

  check not dep.matches("nim", "1.6.3")
  check not dep.matches("nim", "0.7.4")
  check not dep.matches("nim", "1.5.9")
  check not dep.matches("nim", "1.6.4-beta")
