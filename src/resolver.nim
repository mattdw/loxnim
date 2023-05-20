import std/tables

import loxtypes
import ast
import token
import error

proc newResolver*(interp: LoxInterp): LoxResolver =
    result = LoxResolver(interp: interp, scopes: newSeq[Table[string, bool]]())
    result.currentClass = ClassType.t_NOCLASS
    # result.scopes.add(Table[string, bool]())

method resolve(self: var LoxResolver, exp: Expr) {.base.} =
    echo "reached base case resolve/exp"
    echo repr(exp)
    discard

method resolve(self: var LoxResolver, stmt: Stmt) {.base.} =
    echo "reached base case resolve/stmt"
    discard


func scopesEmpty(self: var LoxResolver): bool =
    return self.scopes.len() == 0

func peek[T](l: seq[T]): T =
    l[l.high()]

proc declare(self: var LoxResolver, name: Token) =
    if self.scopesEmpty(): return
    self.scopes[self.scopes.high()][name.lexeme] = false

proc define(self: var LoxResolver, name: Token) =
    if self.scopesEmpty(): return
    self.scopes[self.scopes.high()][name.lexeme] = true

proc beginScope(self: var LoxResolver) =
    self.scopes.add(Table[string, bool]())

proc endScope(self: var LoxResolver) =
    discard self.scopes.pop()

proc resolve(self: var LoxInterp, exp: Expr, depth: int) =
    if exp.id == 0:
        exp.id = nextId()
    self.locals[exp.id] = depth

proc resolveLocal(self: var LoxResolver, exp: Expr, name: Token) =
    if self.scopesEmpty():
        return
    for i in countDown(self.scopes.high(), self.scopes.low()):
        if self.scopes[i].hasKey(name.lexeme):
            self.interp.resolve(exp, self.scopes.high() - i)
            return

proc resolve*(self: var LoxResolver, stmts: seq[Stmt])
proc resolveFunction(self: var LoxResolver, function: Function, functionType: FunctionType) =
    self.beginScope()
    for param in function.params:
        self.declare(param)
        self.define(param)
    self.resolve(function.body)
    self.endScope()

proc resolveFunction(self: var LoxResolver, function: Function) =
    resolveFunction(self, function, FunctionType.t_FUNCTION)

method resolve(self: var LoxResolver, exp: Variable) =
    if not self.scopesEmpty() and
    self.scopes.peek().getOrDefault(exp.name.lexeme, true) == false:
        self.interp.lox[].error(exp.name, "Can't read local variable in its own initializer.")

    self.resolveLocal(exp, exp.name)

method resolve(self: var LoxResolver, exp: Assign) =
    self.resolve(exp.value)
    self.resolveLocal(exp, exp.name)

method resolve(self: var LoxResolver, stmt: ExprStmt) =
    self.resolve(stmt.expression)

method resolve(self: var LoxResolver, stmt: IfStmt) =
    self.resolve(stmt.condition)
    self.resolve(stmt.thenBranch)
    if not stmt.elseBranch.isNil:
        self.resolve(stmt.elseBranch)

method resolve(self: var LoxResolver, stmt: PrintStmt) =
    self.resolve(stmt.expression)

method resolve(self: var LoxResolver, stmt: ReturnStmt) =
    if stmt.value != nil:
        # if self.currentFunction == FunctionType.t_INITIALIZER:
        #     discard
        self.resolve(stmt.value)

method resolve(self: var LoxResolver, stmt: WhileStmt) =
    self.resolve(stmt.condition)
    self.resolve(stmt.body)

method resolve(self: var LoxResolver, exp: Binary) =
    self.resolve(exp.left)
    self.resolve(exp.right)

method resolve(self: var LoxResolver, exp: Call) =
    self.resolve(exp.callee)

    for a in exp.arguments:
        self.resolve(a)

method resolve(self: var LoxResolver, exp: Get) =
    self.resolve(exp.obj)

method resolve(self: var LoxResolver, exp: SetExpr) =
    self.resolve(exp.value)
    self.resolve(exp.obj)

method resolve(self: var LoxResolver, exp: ThisExpr) =
    if self.currentClass == ClassType.t_NOCLASS:
        self.interp.lox[].error(exp.keyword,
            "Can't use 'this' outside of a class.")
        return
    self.resolveLocal(exp, exp.keyword)

method resolve(self: var LoxResolver, exp: Grouping) =
    self.resolve(exp.expression)

method resolve(self: var LoxResolver, exp: Literal) =
    discard

method resolve(self: var LoxResolver, exp: Logical) =
    self.resolve(exp.left)
    self.resolve(exp.right)

method resolve(self: var LoxResolver, exp: Unary) =
    self.resolve(exp.right)

method resolve(self: var LoxResolver, stmt: Function) =
    self.declare(stmt.name)
    self.define(stmt.name)

    self.resolveFunction(stmt)

method resolve(self: var LoxResolver, stmt: VarStmt) =
    self.declare(stmt.name)
    if not stmt.initializer.isNil:
        self.resolve(stmt.initializer)
    self.define(stmt.name)

method resolve(self: var LoxResolver, stmt: ClassStmt) =
    let enclosingClass = self.currentClass
    self.currentClass = ClassType.t_CLASS

    self.declare(stmt.name)
    self.define(stmt.name)

    self.beginScope()
    self.scopes[self.scopes.high()]["this"] = true

    for `method` in stmt.methods:
        var decl = FunctionType.t_METHOD
        if `method`.name.lexeme == "init":
            decl = FunctionType.t_INITIALIZER
        self.resolveFunction(`method`, decl)

    self.endScope()
    self.currentClass = enclosingClass

proc resolve*(self: var LoxResolver, stmts: seq[Stmt]) =
    for s in stmts:
        self.resolve(s)

method resolve(self: var LoxResolver, stmt: Block) =
    self.beginScope()
    self.resolve(stmt.statements)
    self.endScope()
