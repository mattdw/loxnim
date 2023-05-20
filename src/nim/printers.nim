import std/strformat

import loxtypes
import loxclass

func `$`*(x: LoxNumber): string =
    result = fmt"{x.value}"
    if result[^2..^1] == ".0":
        result = result[0..^3]

func `$`*(x: LoxString): string =
    x.value

func `$`*(x: LoxBool): string =
    $x.value

func `$`*(x: LoxNil): string =
    "nil"


func `$`*(x: LoxObj): string =
    if x of LoxNumber:
        return $LoxNumber(x)
    if x of LoxString:
        return $LoxString(x)
    if x of LoxBool:
        return $LoxBool(x)
    if x of LoxNil:
        return $LoxNil(x)
    if x of LoxClass:
        return $LoxClass(x)
    if x of LoxInstance:
        return $LoxInstance(x)

    return "unknown subclass"

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
