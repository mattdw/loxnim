import token
import ast
import loxtypes
import options
import error

type
    Parser* = object
        lox: Lox
        tokens: seq[Token]
        current: int

    ParseError = object of CatchableError


proc newParser*(lox: Lox, tokens: seq[Token]): Parser =
    Parser(lox: lox, tokens: tokens)

proc error(self: var Parser, tok: Token, msg: string): ref ParseError =
    error(self.lox, tok, msg)
    return (ref ParseError)(msg: msg)

func peek(self: Parser): Token =
    return self.tokens[self.current]

func previous(self: Parser): Token =
    return self.tokens[self.current - 1]

func isAtEnd(self: Parser): bool =
    return self.peek().typ == EOF

proc advance(self: var Parser): Token =
    if not self.isAtEnd():
        self.current += 1
    return self.previous()

proc check(self: var Parser, typ: TokenType): bool =
    if self.isAtEnd(): return false
    return self.peek().typ == typ

proc match(self: var Parser, args: varargs[TokenType]): bool =
    for a in args:
        if self.check(a):
            discard self.advance()
            return true

    return false

proc consume(self: var Parser, typ: TokenType, msg: string): Token =
    if self.check(typ):
        return self.advance()

    raise (ref ParseError)(msg: msg)

proc synchronize(self: var Parser) =
    discard self.advance()
    while not self.isAtEnd():
        if self.previous().typ == SEMICOLON:
            return

        case self.peek().typ
        of CLASS, FUN, VAR, FOR, IF, WHILE, PRINT, RETURN:
            return
        else:
            discard

        discard self.advance()

# set up for recursion
proc expression(self: var Parser): Expr

proc primary(self: var Parser): Expr =
    if self.match(FALSE): return Literal(value: LoxBool(value: false))
    if self.match(TRUE): return Literal(value: LoxBool(value: true))
    if self.match(NIL): return Literal(value: LoxNil())

    if self.match(NUMBER, STRING):
        return Literal(value: self.previous().literal.get())

    if self.match(LEFT_PAREN):
        let exp = self.expression()
        discard self.consume(RIGHT_PAREN, "Expect ')' after expression.")
        return Grouping(expression: exp)

    raise self.error(self.peek(), "Expect expression.")

proc unary(self: var Parser): Expr =
    if self.match(BANG, MINUS):
        let op = self.previous()
        let right = self.unary()
        result = Unary(operator: op, right: right)
        return result

    result = self.primary()

proc factor(self: var Parser): Expr =
    result = self.unary()

    while self.match(SLASH, STAR):
        let op = self.previous()
        let right = self.unary()
        result = Binary(left: result, operator: op, right: right)

proc term(self: var Parser): Expr =
    result = self.factor()

    while self.match(MINUS, PLUS):
        let op = self.previous()
        let right = self.factor()
        result = Binary(left: result, operator: op, right: right)

proc comparison(self: var Parser): Expr =
    result = self.term()

    while self.match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL):
        let op = self.previous()
        let right = self.term()
        result = Binary(left: result, operator: op, right: right)


proc equality(self: var Parser): Expr =
    result = self.comparison()

    while self.match(BANG_EQUAL, EQUAL_EQUAL):
        let operator: Token = self.previous()
        let right: Expr = self.comparison()
        result = Binary(left: result, operator: operator, right: right)

proc expression(self: var Parser): Expr =
    self.equality()

proc parse*(self: var Parser): Expr =
    try:
        return self.expression()
    except ParseError as e:
        return nil
