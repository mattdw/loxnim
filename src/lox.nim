import std/os
import system
import std/strformat

import loxtypes
import scanner
import token


proc run(source: string) =
    var scanner = newScanner(source)
    var tokens: seq[Token]
    tokens = scanner.scanTokens()

    for token in tokens:
        echo token

proc runFile(self: Lox, path: string) =
    let bytes = readFile(path)
    run(bytes)

    if self.hadError:
        quit(65)


proc runPrompt(self: var Lox) =
    while true:
        stdout.write("> ")
        try:
            let line = stdin.readLine()
            run(line)
        except IOError as err:
            break
        self.hadError = false


proc main*(): void =
    let argc = paramCount()
    let argv = commandLineParams()
    var l = Lox()

    echo commandLineParams()

    case argc
    of 1:
        runFile(l, argv[0])
    of 0:
        runPrompt(l)
    else:
        quit(64)
    system.quit()

main()