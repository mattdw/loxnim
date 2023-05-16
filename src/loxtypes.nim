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

    Lox* = object
        hadError*: bool


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

var loxObj*: Lox


proc newLoxString*(v: string): LoxString =
    var s: LoxString
    new(s)
    s.value = v
    result = s

proc newLoxNumber*(v: float): LoxNumber =
    var n: LoxNumber
    new(n)
    n.value = v
    result = n


func `$`*(x: LoxNumber): string =
    fmt"L<{x.value}>"

func `$`*(x: LoxString): string =
    fmt"""`{x.value}`"""

func `$`*(x: LoxObj): string =
    if x of LoxNumber:
        return $LoxNumber(x)
    if x of LoxString:
        return $LoxString(x)
