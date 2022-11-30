import types
import std/[strformat, uri, os, strutils, pegs]

const Space* = {' ', '\t'}

proc newParseError*(pos: int, text: string): ref ParseVersionError =
  ## (Leaked implementation detail) create a new instance of `ParseVersionError`
  ParseVersionError.newException(fmt"At position {pos}: {text}")

proc pathToFileUri*(path: string, root = getCurrentDir()): Uri =
  ## Convert a file path to a URI of the form "file:///path".
  result = initUri()
  result.scheme = "file"
  let absPath = path.absolutePath(root).split({DirSep, AltSep})
  when defined(windows):
    var emptyFirst = false
  for i, p in absPath:
    if i == 0 and p == "":
      when defined(windows):
        emptyFirst = true
      continue
    result.path &= "/"
    when defined(windows):
      if (i == 0 or (emptyFirst and i == 1)) and p.len == 2 and p[0].isAlphaAscii and p[1] == ':':
        result.path &= p[0]
      else:
        result.path &= p
    else:
      result.path &= p

proc absoluteFilePath*(uri: Uri): string =
  ## Convert a URI of the form "file:///path" to an OS-friendly absolute path.
  runnableExamples:
    import std/uri
    let u = parseUri("file:///c/users/me/documents/hello.txt")
    let path = absoluteFilePath(u)

    when defined(windows):
      assert path == "c:\\users\\me\\documents\\hello.txt"
    else:
      assert path == "/c/users/me/documents/hello.txt"
  ##
  if uri.scheme != "file":
    raise ValueError.newException("URI could not be converted to an absolute file path because its scheme is not file://")

  result = uri.path

  when defined(windows):
    let p = sequence(charSet({'/'}), charSet({'a'..'z','A'..'Z'}), charSet({'/'}))
    if uri.hostname == "" and
       result.startsWith(p):
      result = unixToNativePath(result[2..^1], $result[1])
  normalizePath(result)
