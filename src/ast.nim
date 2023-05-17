import std/strformat

import token
import loxtypes

type
    # Expression types

    Expr* = ref object of RootObj

    Binary* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr

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

    Assign* = ref object of Expr
        name*: Token
        value*: Expr

    # Statement types

    Stmt* = ref object of RootObj

    ExprStmt* = ref object of Stmt
        expression*: Expr

    PrintStmt* = ref object of Stmt
        expression*: Expr

    Block* = ref object of Stmt
        statements*: seq[Stmt]

    VarStmt* = ref object of Stmt
        name*: Token
        initializer*: Expr

    IfStmt* = ref object of Stmt
        condition*: Expr
        thenBranch*: Stmt
        elseBranch*: Stmt

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
