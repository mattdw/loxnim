import std/os
import system

import loxtypes
import scanner
import token
import parser
import ast


proc run(self: var Lox, source: string) =
    var scanner = newScanner(self, source)
    var tokens: seq[Token]
    tokens = scanner.scanTokens()

    var parser = newParser(self, tokens)
    let exp = parser.parse()

    if self.hadError:
        return

    echo pp(exp)

proc runFile(self: var Lox, path: string) =
    let bytes = readFile(path)
    self.run(bytes)

    if self.hadError:
        quit(65)

proc runPrompt(self: var Lox) =
    while true:
        stdout.write("> ")
        try:
            let line = stdin.readLine()
            self.run(line)
        except IOError as err:
            break
        self.hadError = false


proc main*(): void =
    let argc = paramCount()
    let argv = commandLineParams()
    var l = Lox()

    case argc
    of 1:
        runFile(l, argv[0])
    of 0:
        runPrompt(l)
    else:
        quit(64)
    system.quit()

main()