module Crysterpreter::Object
  alias ObjectType = String

  INTEGER_OBJ = "INTEGER"
  BOOLEAN_OBJ = "BOOLEAN"
  NULL_OBJ    = "NULL"

  abstract class Object
    abstract def type : ObjectType
    abstract def inspect : String
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
end