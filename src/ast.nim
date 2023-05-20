import std/strformat

import token
import loxtypes

type
    # Expression types

    Expr* = ref object of RootObj
        id*: int

    Assign* = ref object of Expr
        name*: Token
        value*: Expr

    Binary* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr

    Call* = ref object of Expr
        callee*: Expr
        paren*: Token
        arguments*: seq[Expr]

    Grouping* = ref object of Expr
        expression*: Expr

    Literal* = ref object of Expr
        value*: LoxObj

    Logical* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr

    Unary* = ref object of Expr
        operator*: Token
        right*: Expr

    Variable* = ref object of Expr
        name*: Token

    # Statement types

    Stmt* = ref object of RootObj
        id*: int

    Block* = ref object of Stmt
        statements*: seq[Stmt]

    ExprStmt* = ref object of Stmt
        expression*: Expr

    Function* = ref object of Stmt
        name*: Token
        params*: seq[Token]
        body*: seq[Stmt]

    IfStmt* = ref object of Stmt
        condition*: Expr
        thenBranch*: Stmt
        elseBranch*: Stmt

    PrintStmt* = ref object of Stmt
        expression*: Expr

    Return* = ref object of Stmt
        keyword*: Token
        value*: Expr

    VarStmt* = ref object of Stmt
        name*: Token
        initializer*: Expr

    WhileStmt* = ref object of Stmt
        condition*: Expr
        body*: Stmt

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
