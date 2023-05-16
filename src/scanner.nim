import std/strformat
import std/parseutils
import std/tables

import token
import options
import error
import loxtypes

type
    Scanner* = object
        source: string
        tokens: seq[Token]
        start: int
        current: int
        line: int


proc newScanner*(source: string): Scanner =
    result.source = source
    result.tokens = @[]
    result.start = 0
    result.current = 0
    result.line = 0


proc isAtEnd(self: Scanner): bool =
    return self.current >= self.source.len()

proc scanToken(self: var Scanner): void

proc scanTokens*(self: var Scanner): seq[Token] =
    while not self.isAtEnd():
        self.start = self.current
        self.scanToken()

    self.tokens.add(newToken(EOF, "", none(LoxObj), self.line))
    result = self.tokens

proc advance(self: var Scanner): char =
    result = self.source[self.current]
    self.current += 1

proc peek(self: Scanner): char =
    if self.isAtEnd():
        return '\0'
    result = self.source[self.current]

proc peekNext(self: Scanner): char =
    if self.current + 1 >= self.source.len():
        return '\0'
    result = self.source[self.current + 1]

proc match(self: var Scanner, expected: char): bool =
    if self.isAtEnd():
        return false

    if self.source[self.current] != expected:
        return false

    self.current += 1
    return true

proc addToken(self: var Scanner, typ: TokenType, literal: Option[LoxObj]) =
    let text = self.source[self.start..(self.current - 1)]
    self.tokens.add(newToken(typ, text, literal, self.line))

proc addToken(self: var Scanner, typ: TokenType) =
    addToken(self, typ, none(LoxObj))


proc string(self: var Scanner) =
    while self.peek() != '"' and not self.isAtEnd():
        if self.peek() == '\n':
            self.line += 1
        discard self.advance()

    if self.isAtEnd():
        error(loxObj, self.line, "Unterminated string.")
        return

    discard self.advance()
    let value: string = self.source[self.start+1..(self.current - 2)]
    self.addToken(STRING, some(LoxObj(newLoxString(value))))


func isDigit(c: char): bool {.inline.} =
    c in '0'..'9'

proc number(self: var Scanner) =
    while isDigit(self.peek()):
        discard self.advance()

    if self.peek() == '.' and isDigit(self.peekNext()):
        discard self.advance()

    while isDigit(self.peek()):
        discard self.advance()

    var num: float
    let numslice = self.source[self.start..(self.current - 1)]
    let res = parseFloat(numslice, num)

    if res == 0:
        error(loxObj, self.line, fmt"Bad num: {numslice}")
    else:
        self.addToken(NUMBER, some(LoxObj(newLoxNumber(num))))


func isAlpha(c: char): bool {.inline.} =
    c == '_' or c in 'A'..'Z' or c in 'a'..'z'

func isAlphaNumeric(c: char): bool {.inline.} =
    isAlpha(c) or isDigit(c)

proc identifier(self: var Scanner) =
    while isAlphaNumeric(self.peek()):
        discard self.advance()

    let text = self.source[self.start..(self.current - 1)]
    if keywords.hasKey(text):
        self.addToken(keywords[text])
    else:
        self.addToken(IDENTIFIER)

proc scanToken(self: var Scanner): void =
    let c = self.advance()
    case c
    of '(': self.addToken(LEFT_PAREN)
    of ')': self.addToken(RIGHT_PAREN)
    of '{': self.addToken(LEFT_BRACE)
    of '}': self.addToken(RIGHT_BRACE)
    of ',': self.addToken(COMMA)
    of '.': self.addToken(DOT)
    of '-': self.addToken(MINUS)
    of '+': self.addToken(PLUS)
    of ';': self.addToken(SEMICOLON)
    of '*': self.addToken(STAR)
    of '!': self.addToken(if self.match('='): BANG_EQUAL else: BANG)
    of '=': self.addToken(if self.match('='): EQUAL_EQUAL else: EQUAL)
    of '<': self.addToken(if self.match('='): LESS_EQUAL else: LESS)
    of '>': self.addToken(if self.match('='): GREATER_EQUAL else: GREATER)
    of '/':
        if self.match('/'):
            while self.peek() != '\n' and self.isAtEnd() != false:
                discard self.advance()
        else:
            self.addToken(SLASH)
    of ' ', '\r', '\t':
        discard
    of '\n':
        self.line += 1
    of '"':
        self.string()
    of '0'..'9':
        self.number()
    of '_', 'A'..'Z', 'a'..'z':
        self.identifier()
    else:
        error(loxObj, self.line, fmt"Unexpected character: {c}")

