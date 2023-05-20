import std/strformat

import loxtypes
import loxclass
import ast

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
    if x of LoxClass:
        return $LoxClass(x)
    if x of LoxInstance:
        return $LoxInstance(x)

    return "unknown subclass"
