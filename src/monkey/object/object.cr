module Monkey::Object
  alias ObjectType = ::String
  alias BuiltinFunction = Array(Object) -> Object

  INTEGER_OBJ      = "INTEGER"
  BOOLEAN_OBJ      = "BOOLEAN"
  NULL_OBJ         = "NULL"
  RETURN_VALUE_OBJ = "RETURN_VALUE"
  FUNCTION_OBJ     = "FUNCTION"
  ERROR_OBJ        = "ERROR"
  STRING_OBJ       = "STRING"
  BUILTIN_OBJ      = "BUILTIN"

  abstract class Object
    abstract def type : ObjectType
    abstract def inspect : ::String
  end

  class Integer < Object
    getter value : Int64

    def initialize(@value : Int64)
    end

    def type
      INTEGER_OBJ
    end

    def inspect
      @value.to_s
    end
  end

  class Boolean < Object
    getter value : Bool

    def initialize(@value : Bool)
    end

    def type
      BOOLEAN_OBJ
    end

    def inspect
      @value.to_s
    end
  end

  class Null < Object
    def type
      NULL_OBJ
    end

    def inspect
      "null"
    end
  end

  class ReturnValue < Object
    getter value : Object

    def initialize(@value : Object)
    end

    def type
      RETURN_VALUE_OBJ
    end

    def inspect
      @value.inspect
    end
  end

  class Error < Object
    getter message : ::String

    def initialize(@message : ::String)
    end

    def type
      ERROR_OBJ
    end

    def inspect
      "ERROR: #{@message}"
    end
  end

  class Function < Object
    getter parameters : Array(Monkey::AST::Identifier), body : Monkey::AST::BlockStatement, env : Environment

    def initialize(@parameters : Array(Monkey::AST::Identifier), @body : Monkey::AST::BlockStatement, @env : Environment)
    end

    def type
      FUNCTION_OBJ
    end

    def inspect
      "fn(#{@parameters.map(&.string).join(", ")}) {\n#{@body.string}\n}"
    end
  end

  class String < Object
    getter value : ::String

    def initialize(@value : ::String)
    end

    def type
      STRING_OBJ
    end

    def inspect
      @value
    end
  end

  class Builtin < Object
    getter fn : BuiltinFunction

    def initialize(@fn : BuiltinFunction)
    end

    def type
      BUILTIN_OBJ
    end

    def inspect
      "buildin function"
    end
  end
end
