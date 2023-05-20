import std/tables
import std/strformat

import loxtypes
import error
import token
import environment

type
    LoxClass* = ref object of LoxCallable
        name*: string
        methods*: Table[string, LoxFunction]

    LoxInstance* = ref object of LoxObj
        klass*: LoxClass
        fields*: Table[string, LoxObj]


proc newInstance*(klass: LoxClass): LoxInstance =
    result = LoxInstance(klass: klass)
    # result.fields = newTable[string, LoxObj]()


proc findMethod*(klass: LoxClass, name: string): LoxFunction =
    if klass.methods.hasKey(name):
        return klass.methods[name]

    return nil

proc `bind`*(self: LoxFunction, inst: LoxInstance): LoxFunction =
    var env = newEnvironment(self.closure)
    env.define("this", inst)
    return LoxFunction(declaration: self.declaration, closure: env, isInitializer: self.isInitializer)

proc get*(instance: LoxInstance, name: Token): LoxObj =
    if instance.fields.hasKey(name.lexeme):
        return instance.fields[name.lexeme]

    let meth = instance.klass.findMethod(name.lexeme)
    if meth != nil:
        return meth.bind(instance)

    raise (ref RuntimeError)(msg: fmt"{name}: undefined property.")


proc set*(instance: LoxInstance, name: Token, value: LoxObj) =
    instance.fields[name.lexeme] = value


func `$`*(x: LoxClass): string =
    x.name

func `$`*(x: LoxInstance): string =
    return x.klass.name & " instance"
