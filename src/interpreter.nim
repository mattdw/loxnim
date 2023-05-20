import std/strformat
import std/times
import std/strutils
import std/tables

import loxtypes
import loxclass
import token
import error
import environment
import printers

type
    Clock* = ref object of LoxCallable
    Mod* = ref object of LoxCallable
    Format* = ref object of LoxCallable

    ReturnErr = ref object of CatchableError
        value*: LoxObj


func getNum(l: LoxObj): float =
    if l of LoxNumber:
        return LoxNumber(l).value

    raise (ref TypeError)(msg: fmt"Expected a number but got {l}.")

func getStr(l: LoxObj): string =
    if l of LoxString:
        return LoxString(l).value

    raise (ref TypeError)(msg: fmt"Expected a string but got {l}.")

proc formatLoxStr(args: varargs[LoxObj]): LoxString =
    if not (args[0] of LoxString):
        raise (ref RuntimeError)(msg: "First arg to format must be string")

    var s = ""
    var segs = LoxString(args[0]).value.split("{}")
    let args = args[1..args.high()]
    for i in 0..args.high():
        s &= segs[i]
        if args[i] of LoxString:
            s &= LoxString(args[i]).value
        else:
            s &= $args[i]

    s &= segs[args.len()]

    return LoxString(value: s)

method arity(fobj: LoxCallable): int {.base.} = -1
method call(self: var LoxInterp, fobj: LoxCallable, args: varargs[LoxObj]): LoxObj {.base.} =
    raise (ref RuntimeError)(msg: "Unhandled call()")

method arity(fobj: Clock): int = 0
method call(self: var LoxInterp, fobj: Clock, args: varargs[LoxObj]): LoxObj =
    LoxNumber(value: epochTime())

method arity(fobj: Format): int = -1
method call(self: var LoxInterp, fobj: Format, args: varargs[LoxObj]): LoxObj =
    formatLoxStr(args)

method arity(fobj: Mod): int = 2
method call(self: var LoxInterp, fobj: Mod, args: varargs[LoxObj]): LoxObj =
    LoxNumber(value: (args[0].getNum().toInt() mod args[1].getNum().toInt()).toFloat)


proc newInterpreter*(lox: ref Lox): LoxInterp =
    result = LoxInterp()
    result.lox = lox
    result.globals = newEnvironment()
    result.env = result.globals
    result.locals = Table[int, int]()

    result.globals.define("clock", Clock())
    result.globals.define("format", Format())
    result.globals.define("mod", Mod())

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

    # if typeof(l) == typeof(r):
    #     return l == r

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

method eval(self: var LoxInterp, exp: Get): LoxObj =
    let o = self.eval(exp.obj)
    if o of LoxInstance:
        return LoxInstance(o).get(exp.name)

    raise (ref RuntimeError)(msg: fmt"{exp.name}: Only instances have properties.")

method eval(self: var LoxInterp, exp: Literal): LoxObj =
    exp.value

method eval(self: var LoxInterp, exp: Logical): LoxObj =
    let left = self.eval(exp.left)

    if exp.operator.typ == TokenType.OR:
        if isTruthy(left): return left
    else:
        if not isTruthy(left): return left

    return self.eval(exp.right)

method eval(self: var LoxInterp, exp: SetExpr): LoxObj =
    let o = self.eval(exp.obj)

    if not (o of LoxInstance):
        raise (ref RuntimeError)(msg: fmt"{exp.name}: Only instances have fields.")

    let value = self.eval(exp.value)
    LoxInstance(o).set(exp.name, value)

method eval(self: var LoxInterp, exp: Variable): LoxObj =
    if self.locals.hasKey(exp.id):
        let dist: int = self.locals[exp.id]
        return self.env.getAt(dist, exp.name.lexeme)
    else:
        return self.globals.get(exp.name)

method eval(self: var LoxInterp, exp: Grouping): LoxObj =
    self.eval(exp.expression)

method eval(self: var LoxInterp, exp: Assign): LoxObj =
    let val = self.eval(exp.value)
    self.env.assign(exp.name, val)
    return val

method eval(self: var LoxInterp, exp: Call): LoxObj =
    let callee = self.eval(exp.callee)
    var args = newSeq[LoxObj]()
    for arg in exp.arguments:
        args.add(self.eval(arg))

    if not (callee of LoxCallable):
        raise (ref RuntimeError)(msg: "Can only call functions and classes.")

    let fun = LoxCallable(callee)

    let arity = fun.arity()
    if arity != -1 and args.len() != arity:
        raise (ref RuntimeError)(msg: fmt"Expected {arity} arguments but got {args.len()}.")

    return call(self, fun, args)

method eval(self: var LoxInterp, exp: ThisExpr): LoxObj =
    self.env.get(exp.keyword)

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

method eval(self: var LoxInterp, stmt: ReturnStmt) =
    var val: LoxObj = LoxNil()
    if not stmt.value.isNil:
        val = self.eval(stmt.value)

    raise ReturnErr(value: val)


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

method arity(fobj: LoxFunction): int =
    fobj.declaration.params.len()
method call(self: var LoxInterp, fobj: LoxFunction, args: varargs[LoxObj]): LoxObj =
    var env = newEnvironment(fobj.closure)
    let params = fobj.declaration.params;
    for i in 0..params.high():
        env.define(params[i].lexeme, args[i])

    try:
        self.evalBlock(fobj.declaration.body, env)
    except ReturnErr as ret:
        if fobj.isInitializer: return fobj.closure.getAt(0, "this")
        return ret.value

    return LoxNil()

method eval(self: var LoxInterp, stmt: Function) =
    var fun: LoxFunction
    fun = LoxFunction(declaration: stmt, closure: self.env, isInitializer: false)
    self.env.define(stmt.name.lexeme, fun)

method eval(self: var LoxInterp, stmt: IfStmt) =
    if isTruthy(self.eval(stmt.condition)):
        self.eval(stmt.thenBranch)
    elif not stmt.elseBranch.isNil:
        self.eval(stmt.elseBranch)

method eval(self: var LoxInterp, stmt: WhileStmt) =
    while isTruthy(self.eval(stmt.condition)):
        self.eval(stmt.body)

method arity(fobj: LoxClass): int =
    let init = fobj.findMethod("init")
    if init.isNil:
        return 0

    return init.arity

method call(self: var LoxInterp, fobj: LoxClass, args: varargs[LoxObj]): LoxObj =
    var inst = newInstance(fobj)

    let init: LoxFunction = fobj.findMethod("init")
    if not init.isNil:
        var boundInit = init.bind(inst)
        discard call(self, boundInit, args)

    result = inst

method eval(self: var LoxInterp, stmt: ClassStmt) =
    self.env.define(stmt.name.lexeme, nil)

    var methods = Table[string, LoxFunction]()
    for meth in stmt.methods:
        let function = LoxFunction(declaration: meth, closure: self.env,
            isInitializer: meth.name.lexeme == "init")
        methods[meth.name.lexeme] = function

    let klass = LoxClass(name: stmt.name.lexeme, methods: methods)
    self.env.assign(stmt.name, klass)

proc interpret*(self: var LoxInterp, statements: seq[Stmt]) =
    try:
        for s in statements:
            self.eval(s)
    except RuntimeError as e:
        self.lox.runtimeError(e[])
