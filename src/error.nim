import loxtype
import std/strformat

proc report*(self: var Lox, line: int, where: string, message: string) =
    echo fmt"[line {line}] Error {where}: {message}"
    self.hadError = true

proc error*(self: var Lox, line: int, message: string) =
    report(self, line, "", message)
