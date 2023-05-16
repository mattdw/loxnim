import std/strformat
import options

import loxtypes

type
    Token* = object
        typ: TokenType
        lexeme: string
        literal: Option[LoxObj]
        line: int


proc newToken*(typ: TokenType, lexeme: string, literal: Option[LoxObj], line: int): Token =
    result.typ = typ
    result.lexeme = lexeme
    result.literal = literal
    result.line = line

proc `$`*(self: Token): string =
    case self.typ
    of IDENTIFIER:
        return fmt"ID({self.lexeme})"
    of STRING:
        return '"' & $LoxString(self.literal.get()).value & '"'
    of NUMBER:
        return $LoxNumber(self.literal.get()).value
    else:
        return $self.typ
