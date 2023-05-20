import std/tables
import std/strformat
import std/options

type
    TokenType* = enum
        LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
        COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR

        BANG, BANG_EQUAL, EQUAL, EQUAL_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL

        IDENTIFIER, STRING, NUMBER

        AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR, PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE

        EOF

    FunctionType* = enum
        t_FUNCTION,
        t_METHOD

    ##

    Token* = object
        typ*: TokenType
        lexeme*: string
        literal*: Option[LoxObj]
        line*: int

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

    Get* = ref object of Expr
        obj*: Expr
        name*: Token

    Grouping* = ref object of Expr
        expression*: Expr

    Literal* = ref object of Expr
        value*: LoxObj

    Logical* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr

    SetExpr* = ref object of Expr
        obj*: Expr
        name*: Token
        value*: Expr

    ThisExpr* = ref object of Expr
        keyword*: Token

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

    ClassStmt* = ref object of Stmt
        name*: Token
        methods*: seq[Function]

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

    ReturnStmt* = ref object of Stmt
        keyword*: Token
        value*: Expr

    VarStmt* = ref object of Stmt
        name*: Token
        initializer*: Expr

    WhileStmt* = ref object of Stmt
        condition*: Expr
        body*: Stmt

    ##

    LoxObj* = ref object of RootObj

    LoxString* = ref object of LoxObj
        value*: string

    LoxNumber* = ref object of LoxObj
        value*: float

    LoxBool* = ref object of LoxObj
        value*: bool

    LoxNil* = ref object of LoxObj

    Environment* = ref object
        enclosing*: Environment
        values*: Table[string, LoxObj]

    LoxInterp* = ref object
        lox*: ref Lox
        globals*: Environment
        env*: Environment
        locals*: Table[int, int]

    LoxResolver* = ref object
        interp*: LoxInterp
        scopes*: seq[Table[string, bool]]

    LoxCallable* = ref object of LoxObj
        # arity*: int
        # call*: proc(interp: var LoxInterp, args: varargs[LoxObj]): LoxObj

    LoxFunction* = ref object of LoxCallable
        declaration*: Function
        closure*: Environment

    Lox* = object
        interpreter*: LoxInterp
        hadError*: bool
        hadRuntimeError*: bool


const keywords* = {
    "and": AND,
    "class": CLASS,
    "else": ELSE,
    "false": FALSE,
    "for": FOR,
    "fun": FUN,
    "if": IF,
    "nil": NIL,
    "or": OR,
    "print": PRINT,
    "return": RETURN,
    "super": SUPER,
    "this": THIS,
    "true": TRUE,
    "var": VAR,
    "while": WHILE
}.toTable()

proc newLoxString*(v: string): LoxString =
    result = LoxString(value: v)

proc newLoxNumber*(v: float): LoxNumber =
    result = LoxNumber(value: v)
