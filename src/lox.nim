import std/os
import system
import std/tables

import loxtypes
import scanner
import token
import parser
import ast
import interpreter
import error
import resolver

proc run(self: var Lox, source: string) =
    var scanner = newScanner(self, source)
    var tokens: seq[Token]
    tokens = scanner.scanTokens()

    var parser = newParser(self, tokens)
    let stmts = parser.parse()

    if self.hadError:
        return

    var resolver = newResolver(self.interpreter)
    resolver.resolve(stmts)

    self.interpreter.interpret(stmts)

    # echo pp(exp)

proc runFile(self: var Lox, path: string) =
    let bytes = readFile(path)
    self.run(bytes)

    if self.hadError:
        quit(65)

    if self.hadRuntimeError:
        quit(70)

proc runPrompt(self: var Lox) =
    while true:
        stdout.write("> ")
        try:
            let line = stdin.readLine()
            self.run(line)
        except ParseError as e:
            echo e.msg
        except IOError as err:
            break
        self.hadError = false


proc main*(): void =
    let argc = paramCount()
    let argv = commandLineParams()
    var l = (ref Lox)()
    l.interpreter = newInterpreter(l)

    case argc
    of 1:
        runFile(l[], argv[0])
    of 0:
        runPrompt(l[])
    else:
        quit(64)
    system.quit()

main()