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

    if self.match(IDENTIFIER):
        return Variable(name: self.previous())

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

proc `and`(self: var Parser): Expr =
    result = self.equality()

    while self.match(AND):
        let operator = self.previous()
        let right = self.equality()
        result = Logical(left: result, operator: operator, right: right)

proc `or`(self: var Parser): Expr =
    result = self.`and`()

    while self.match(OR):
        let op = self.previous()
        let right = self.`and`()
        result = Logical(left: result, operator: op, right: right)

proc assignment(self: var Parser): Expr =
    let exp = self.`or`()

    if self.match(EQUAL):
        let equals = self.previous()
        let value = self.assignment()

        if exp of Variable:
            let name = Variable(exp).name
            return Assign(name: name, value: value)

        raise self.error(equals, "Invalid assignment target.")

    return exp

proc expression(self: var Parser): Expr =
    self.assignment()

proc printStatement(self: var Parser): Stmt =
    let exp = self.expression()
    discard self.consume(SEMICOLON, "Expect ';' after value.")
    return PrintStmt(expression: exp)

proc expressionStatement(self: var Parser): Stmt =
    let exp = self.expression()
    discard self.consume(SEMICOLON, "Expect ';' after value.")
    return ExprStmt(expression: exp)



proc `block`(self: var Parser): seq[Stmt]
proc ifStatement(self: var Parser): Stmt
proc whileStatement(self: var Parser): Stmt
proc forStatement(self: var Parser): Stmt

proc statement(self: var Parser): Stmt =
    if self.match(FOR): return self.forStatement()
    if self.match(IF): return self.ifStatement()
    if self.match(PRINT): return self.printStatement()
    if self.match(WHILE): return self.whileStatement()
    if self.match(LEFT_BRACE): return Block(statements: self.block())

    return self.expressionStatement()

proc ifStatement(self: var Parser): Stmt =
    discard self.consume(LEFT_PAREN, "Expect '(' after 'if'.")
    let condition = self.expression()
    discard self.consume(RIGHT_PAREN, "Expect ')' after 'if'.")

    let thenBranch = self.statement()
    var elseBranch: Stmt = nil

    if self.match(ELSE):
        elseBranch = self.statement()

    return IfStmt(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)

proc whileStatement(self: var Parser): Stmt =
    discard self.consume(LEFT_PAREN, "Expect '(' after 'while'.")
    let condition = self.expression()
    discard self.consume(RIGHT_PAREN, "Expect ')' after condition.")
    let body = self.statement()

    return WhileStmt(condition: condition, body: body)

proc varDeclaration(self: var Parser): Stmt =
    let name = self.consume(IDENTIFIER, "Expect variable name.")
    var initializer: Expr = nil
    if self.match(EQUAL):
        initializer = self.expression()

    discard self.consume(SEMICOLON, "Expect ';' after variable declaration.")
    return VarStmt(name: name, initializer: initializer)

proc forStatement(self: var Parser): Stmt =
    discard self.consume(LEFT_PAREN, "Expect '(' after 'for'.")

    var initializer: Stmt
    if self.match(SEMICOLON):
        initializer = nil
    elif self.match(VAR):
        initializer = self.varDeclaration()
    else:
        initializer = self.expressionStatement()

    var condition: Expr = nil
    if not self.check(SEMICOLON):
        condition = self.expression()

    discard self.consume(SEMICOLON, "Expect ';' after loop condition.")

    var increment: Expr = nil
    if not self.check(RIGHT_PAREN):
        increment = self.expression()

    discard self.consume(RIGHT_PAREN, "Expect ')' after for clauses.")

    var body = self.statement()

    if not increment.isNil:
        body = Block(statements: @[body, ExprStmt(expression: increment)])

    if condition.isNil: condition = Literal(value: LoxBool(value: true))
    body = WhileStmt(condition: condition, body: body)

    if not initializer.isNil:
        body = Block(statements: @[initializer, body])

    return body


proc declaration(self: var Parser): Stmt =
    try:
        if self.match(VAR):
            return self.varDeclaration()
        return self.statement()
    except ParseError as e:
        self.synchronize()
        raise e

proc `block`(self: var Parser): seq[Stmt] =
    result = newSeq[Stmt]()
    while not self.check(RIGHT_BRACE) and not self.isAtEnd():
        result.add(self.declaration())

    discard self.consume(RIGHT_BRACE, "Expect '}' after block.")


proc parse*(self: var Parser): seq[Stmt] =
    var stmts = newSeq[Stmt]()
    while not self.isAtEnd():
        stmts.add(self.declaration())

    return stmts