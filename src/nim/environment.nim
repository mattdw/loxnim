import std/tables
import std/strformat

import loxtypes
import error
import token

proc newEnvironment*(): Environment =
    result = Environment()
    result.values = initTable[string, LoxObj]()

proc newEnvironment*(enclosing: Environment): Environment =
    result = Environment()
    result.values = initTable[string, LoxObj]()
    result.enclosing = enclosing

proc define*(env: var Environment, name: string, value: LoxObj) =
    # echo name, "==>", value
    env.values[name] = value

proc get*(env: var Environment, name: Token): LoxObj =
    # echo env.values
    if env.values.hasKey(name.lexeme):
        return env.values[name.lexeme]

    if not env.enclosing.isNil:
        return env.enclosing.get(name)

    raise (ref RuntimeError)(msg: fmt"[Line {name.line}] Undefined variable '{name.lexeme}'.")

proc ancestor(self: var Environment, distance: int): Environment =
    var env = self
    for i in 0..(distance - 1):
        env = env.enclosing

    result = env

proc getAt*(env: var Environment, distance: int, name: string): LoxObj =
    return env.ancestor(distance).values[name]

proc assign*(env: var Environment, name: Token, value: LoxObj) =
    if env.values.hasKey(name.lexeme):
        env.values[name.lexeme] = value
        return

    if not env.enclosing.isNil:
        env.enclosing.assign(name, value)
        return

    raise (ref RuntimeError)(msg: fmt"[Line {name.line}] Undefined variable '{name.lexeme}'.")
