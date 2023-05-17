import std/strformat

import ast
import loxtypes
import token
import error

type
    LoxInterp* = object
        lox: Lox


func getNum(l: LoxObj): float =
    if l of LoxNumber:
        return LoxNumber(l).value

    raise (ref TypeError)(msg: fmt"Expected a number but got {l}.")

func getStr(l: LoxObj): string =
    if l of LoxString:
        return LoxString(l).value

    raise (ref TypeError)(msg: fmt"Expected a string but got {l}.")

func isTruthy(o: LoxObj): bool =
    if o of LoxNil:
        return false

    if o of LoxBool:
        return LoxBool(o).value

    if o of LoxNumber:
        return not (LoxNumber(o).value == 0.0)

    # if o of LoxString:
    #     return not (LoxString(o).value.len() == 0)

    return true

func isEqual(l: LoxObj, r: LoxObj): bool =
    if l of LoxNil and r of LoxNil:
        return true

    if l of LoxBool and r of LoxBool:
        return LoxBool(l).value == LoxBool(r).value

    if l of LoxNumber and r of LoxNumber:
        return l.getNum() == r.getNum()

    if l of LoxString and r of LoxString:
        return l.getStr() == r.getStr()

    return false


func cmp[T](o: TokenType, l: T, r: T): bool =
    case o
    of GREATER:
        return l > r
    of GREATER_EQUAL:
        return l >= r
    of LESS:
        return l < r
    of LESS_EQUAL:
        return l <= r
    else:
        discard

func cmp(o: TokenType, l: LoxObj, r: LoxObj): bool =
    if l of LoxNumber and r of LoxNumber:
        return cmp[float](o, l.getNum(), r.getNum())
    if l of LoxString and r of LoxString:
        return cmp[string](o, l.getStr(), r.getStr())
    if l of LoxBool and r of LoxBool:
        return cmp[bool](o, LoxBool(l).value, LoxBool(r).value)

    raise (ref TypeError)(msg: fmt"Can't compare different types {l} and {r}")

method eval(exp: Expr): LoxObj {.base.} =
    raise (ref RuntimeError)(msg: "Reached LoxObj base eval!")
    LoxNil()

method eval(exp: Literal): LoxObj =
    return exp.value

method eval(exp: Grouping): LoxObj =
    eval(exp.expression)

method eval(exp: Unary): LoxObj =
    let r = eval(exp.right)

    case exp.operator.typ
    of MINUS:
        if not (r of LoxNumber):
            raise (ref TypeError)(msg: "Expected Number")
        let n = LoxNumber(r).value
        return LoxNumber(value: -n)
    of BANG:
        return LoxBool(value: not isTruthy(r))
    else:
        raise (ref RuntimeError)(msg: fmt"Unexpected operator {exp.operator}")

    raise (ref RuntimeError)(msg: "Unreachable in eval Unary")

method eval(exp: Binary): LoxObj =
    let l = eval(exp.left)
    let r = eval(exp.right)

    case exp.operator.typ
    # of GREATER:
    #     return LoxBool(value: l.getNum() > r.getNum())
    # of GREATER_EQUAL:
    #     return LoxBool(value: l.getNum() >= r.getNum())
    # of LESS:
    #     return LoxBool(value: l.getNum() < r.getNum())
    # of LESS_EQUAL:
    #     return LoxBool(value: l.getNum() <= r.getNum())
    of GREATER, GREATER_EQUAL, LESS, LESS_EQUAL:
        return LoxBool(value: cmp(exp.operator.typ, l, r))
    of BANG_EQUAL:
        return LoxBool(value: not isEqual(l, r))
    of EQUAL_EQUAL:
        return LoxBool(value: isEqual(l, r))
    of MINUS:
        return LoxNumber(value: l.getNum() - r.getNum())
    of SLASH:
        return LoxNumber(value: l.getNum() / r.getNum())
    of STAR:
        return LoxNumber(value: l.getNum() * r.getNum())
    of PLUS:
        if l of LoxNumber:
            return LoxNumber(value: l.getNum() + r.getNum())
        else:
            return LoxString(value: l.getStr() & r.getStr())

    else:
        raise (ref RuntimeError)(msg: fmt"Unmatched operator {exp.operator}")

proc interpret*(self: var LoxInterp, exp: Expr) =
    try:
        let val = eval(exp)
        echo $val
    except RuntimeError as e:
        self.lox.runtimeError(e[])
