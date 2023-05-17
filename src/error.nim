import loxtypes
import token
import std/strformat

proc report*(self: var Lox, line: int, where: string, message: string) =
    echo fmt"[line {line}] Error {where}: {message}"
    self.hadError = true

proc error*(self: var Lox, line: int, message: string) =
    report(self, line, "", message)


proc error*(self: var Lox, tok: Token, msg: string) =
    if tok.typ() == EOF:
        self.report(tok.line, "at end", msg)
    else:
        self.report(tok.line, fmt"at '{tok.lexeme}'", msg)

