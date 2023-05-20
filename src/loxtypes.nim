import std/tables
import std/strformat

type
    TokenType* = enum
        LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
        COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR

        BANG, BANG_EQUAL, EQUAL, EQUAL_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL

        IDENTIFIER, STRING, NUMBER

        AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR, PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE

        EOF

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

