import std/strformat
import options

import loxtypes

proc newToken*(typ: TokenType, lexeme: string, literal: Option[LoxObj], line: int): Token =
    result.typ = typ
    result.lexeme = lexeme
    result.literal = literal
    result.line = line

# getters

func lexeme*(t: Token): string {.inline.} =
    t.lexeme

func literal*(t: Token): Option[LoxObj] {.inline.} =
    t.literal

func typ*(t: Token): TokenType {.inline.} =
    t.typ

func line*(t: Token): int {.inline.} =
    t.line

proc `$`*(self: Token): string {.inline.} =
    case self.typ
    of IDENTIFIER:
        return fmt"ID({self.lexeme})"
    of STRING:
        return '"' & $LoxString(self.literal.get()).value & '"'
    of NUMBER:
        return $LoxNumber(self.literal.get()).value
    else:
        return $self.typ
