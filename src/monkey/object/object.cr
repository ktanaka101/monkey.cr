module Monkey::Object
  alias ObjectType = ::String
  alias BuiltinFunction = ::Array(Object) -> Object

  INTEGER_OBJ      = "INTEGER"
  BOOLEAN_OBJ      = "BOOLEAN"
  NULL_OBJ         = "NULL"
  RETURN_VALUE_OBJ = "RETURN_VALUE"
  FUNCTION_OBJ     = "FUNCTION"
  ERROR_OBJ        = "ERROR"
  STRING_OBJ       = "STRING"
  BUILTIN_OBJ      = "BUILTIN"
  ARRAY_OBJ        = "ARRAY"
  HASH_OBJ         = "HASH"

  abstract class Object
    abstract def type : ObjectType
    abstract def inspect : ::String
  end

  module Hashable
    abstract def hash_key : HashKey
  end

  class Integer < Object
    include Hashable

    getter value : Int64

    def initialize(@value : Int64)
    end

    def type : ObjectType
      INTEGER_OBJ
    end

    def inspect : ::String
      @value.to_s
    end

    def hash_key : HashKey
      HashKey.new(self.type, @value.to_u64)
    end
  end

  class Boolean < Object
    include Hashable

    getter value : Bool

    def initialize(@value : Bool)
    end

    def type : ObjectType
      BOOLEAN_OBJ
    end

    def inspect : ::String
      @value.to_s
    end

    def hash_key : HashKey
      HashKey.new(self.type, @value ? 1_u64 : 0_u64)
    end
  end

  class Null < Object
    def type : ObjectType
      NULL_OBJ
    end

    def inspect : ::String
      "null"
    end
  end

  class ReturnValue < Object
    getter value : Object

    def initialize(@value : Object)
    end

    def type : ObjectType
      RETURN_VALUE_OBJ
    end

    def inspect : ::String
      @value.inspect
    end
  end

  class Error < Object
    getter message : ::String

    def initialize(@message : ::String)
    end

    def type : ObjectType
      ERROR_OBJ
    end

    def inspect : ::String
      "ERROR: #{@message}"
    end
  end

  class Function < Object
    getter parameters : ::Array(AST::Identifier), body : AST::BlockStatement, env : Environment

    def initialize(@parameters : ::Array(AST::Identifier), @body : AST::BlockStatement, @env : Environment)
    end

    def type : ObjectType
      FUNCTION_OBJ
    end

    def inspect : ::String
      "fn(#{@parameters.map(&.string).join(", ")}) {\n#{@body.string}\n}"
    end
  end

  class String < Object
    include Hashable

    getter value : ::String

    def initialize(@value : ::String)
    end

    def type : ObjectType
      STRING_OBJ
    end

    def inspect : ::String
      @value
    end

    def hash_key : HashKey
      HashKey.new(self.type, @value.hash)
    end
  end

  class Builtin < Object
    getter fn : BuiltinFunction

    def initialize(@fn : BuiltinFunction)
    end

    def type : ObjectType
      BUILTIN_OBJ
    end

    def inspect : ::String
      "buildin function"
    end
  end

  class Array < Object
    getter elements

    def initialize(@elements : ::Array(Object))
    end

    def type : ObjectType
      ARRAY_OBJ
    end

    def inspect : ::String
      %([#{@elements.map(&.inspect).join(", ")}])
    end
  end

  class Hash < Object
    getter pairs

    def initialize(@pairs : ::Hash(HashKey, HashPair))
    end

    def type : ObjectType
      HASH_OBJ
    end

    def inspect : ::String
      hs_string = @pairs.map { |key, value|
        "#{key.inspect}: #{value.inspect}"
      }
        .join(", ")

      "{#{hs_string}}"
    end
  end

  class HashKey
    getter type, value

    def initialize(@type : ::String, @value : UInt64)
    end

    # Monkey uses #== to compare key of hash.
    def ==(other : HashKey)
      hash == other.hash
    end

    # Crystal uses #hash to compare key of hash.
    def hash
      @value
    end
  end

  record HashPair, key : Object, value : Object
end
