require "./object"

module Monkey::Object
  class Environment
    def self.new_enclose(outer : Environment) : Environment
      Environment.new(outer)
    end

    def initialize(@outer : Environment? = nil)
      @hs = {} of String => Monkey::Object::Object
    end

    def []?(key) : Monkey::Object::Object?
      obj = @hs[key]?
      outer = @outer
      if obj.nil? && outer
        outer[key]?
      else
        obj
      end
    end

    def []=(key : String, value : Monkey::Object::Object)
      @hs[key] = value
    end
  end
end
