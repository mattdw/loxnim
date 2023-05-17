import std/strformat

import ast
import loxtypes
import token
import error
import environment

proc newInterpreter*(lox: ref Lox): LoxInterp =
    result.lox = lox
    result.env = newEnvironment()

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

method eval(self: var LoxInterp, exp: Expr): LoxObj {.base.} =
    raise (ref RuntimeError)(msg: "Reached LoxObj base eval!")
    LoxNil()

method eval(self: var LoxInterp, exp: Literal): LoxObj =
    exp.value

method eval(self: var LoxInterp, exp: Logical): LoxObj =
    let left = self.eval(exp.left)

    if exp.operator.typ == TokenType.OR:
        if isTruthy(left): return left
    else:
        if not isTruthy(left): return left

    return self.eval(exp.right)

method eval(self: var LoxInterp, exp: Variable): LoxObj =
    self.env.get(exp.name)

method eval(self: var LoxInterp, exp: Grouping): LoxObj =
    self.eval(exp.expression)

method eval(self: var LoxInterp, exp: Assign): LoxObj =
    let val = self.eval(exp.value)
    self.env.assign(exp.name, val)
    return val

method eval(self: var LoxInterp, exp: Unary): LoxObj =
    let r = self.eval(exp.right)

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

method eval(self: var LoxInterp, exp: Binary): LoxObj =
    let l = self.eval(exp.left)
    let r = self.eval(exp.right)

    case exp.operator.typ
    of GREATER, GREATER_EQUAL, LESS, LESS_EQUAL:
        return LoxBool(value: cmp(exp.operator.typ, l, r))
    of BANG_EQUAL:
        return LoxBool(value: not isEqual(l, r))
    of EQUAL_EQUAL:
        return LoxBool(value: isEqual(l, r))
    of MINUS:
        return LoxNumber(value: l.getNum() - r.getNum())
    of SLASH:
        let rf = r.getNum()
        if rf == 0:
            raise (ref ZeroDivError)()
        return LoxNumber(value: l.getNum() / rf)
    of STAR:
        return LoxNumber(value: l.getNum() * r.getNum())
    of PLUS:
        if l of LoxNumber:
            return LoxNumber(value: l.getNum() + r.getNum())
        else:
            return LoxString(value: l.getStr() & r.getStr())

    else:
        raise (ref RuntimeError)(msg: fmt"Unmatched operator {exp.operator}")


method eval(self: var LoxInterp, stmt: Stmt) {.base.} =
    raise (ref RuntimeError)(msg: "Reached Stmt base case!")

method eval(self: var LoxInterp, stmt: ExprStmt) =
    discard self.eval(stmt.expression)

method eval(self: var LoxInterp, stmt: PrintStmt) =
    let val = self.eval(stmt.expression)
    echo val

method eval(self: var LoxInterp, stmt: VarStmt) =
    var val: LoxObj = LoxNil()
    if not stmt.initializer.isNil:
        val = self.eval(stmt.initializer)

    self.env.define(stmt.name.lexeme, val)

proc evalBlock(self: var LoxInterp, statements: seq[Stmt], env: Environment) =
    let prev = self.env
    try:
        self.env = env

        for s in statements:
            self.eval(s)
    finally:
        self.env = prev

method eval(self: var LoxInterp, stmt: Block) =
    self.evalBlock(stmt.statements, newEnvironment(self.env))
    return

method eval(self: var LoxInterp, stmt: IfStmt) =
    if isTruthy(self.eval(stmt.condition)):
        self.eval(stmt.thenBranch)
    elif not stmt.elseBranch.isNil:
        self.eval(stmt.elseBranch)

method eval(self: var LoxInterp, stmt: WhileStmt) =
    while isTruthy(self.eval(stmt.condition)):
        self.eval(stmt.body)

proc interpret*(self: var LoxInterp, statements: seq[Stmt]) =
    try:
        for s in statements:
            self.eval(s)
    except RuntimeError as e:
        self.lox.runtimeError(e[])
