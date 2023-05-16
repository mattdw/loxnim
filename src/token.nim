import tokentype
import std/strformat
import options

type
    Token* = object
        typ: TokenType
        lexeme: string
        literal: Option[RootObj]
        line: int


proc newToken*(typ: TokenType, lexeme: string, literal: Option[RootObj], line: int): Token =
    result.typ = typ
    result.lexeme = lexeme
    result.literal = literal
    result.line = line

proc `$`*(self: Token): string =
    fmt"{$self.type} {self.lexeme} {self.literal}"