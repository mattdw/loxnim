import std/tables
import std/strformat

import loxtypes
import error
import token

proc newEnvironment*(): Environment =
    result.values = initTable[string, LoxObj]()

proc define*(env: var Environment, name: string, value: LoxObj) =
    # echo name, "==>", value
    env.values[name] = value

proc get*(env: var Environment, name: Token): LoxObj =
    # echo env.values
    if env.values.hasKey(name.lexeme):
        return env.values[name.lexeme]

    raise (ref RuntimeError)(msg: fmt"Undefined variable '{name.lexeme}'.")
