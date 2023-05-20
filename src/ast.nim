import std/strformat

import token
import loxtypes
import printers

method pp*(exp: Expr): string {.base.} =
    fmt"(not implemented for {repr(exp)})"

func parenthesize(name: string, args: varargs[Expr]): string =
    result = fmt"({name}"
    for e in args:
        result &= " " & pp(e)

    result &= ")"

method pp*(exp: Binary): string =
    parenthesize(exp.operator.lexeme, exp.left, exp.right)

method pp*(exp: Grouping): string =
    parenthesize("group", exp.expression)

method pp*(exp: Literal): string =
    if exp.value.isNil: return "nil"
    return $exp.value

method pp*(exp: Unary): string =
    return parenthesize(exp.operator.lexeme, exp.right)


var lastId = 0

proc nextId*(): int =
    lastId += 1
    result = lastId
