require "./object"

module Monkey::Object
  class Environment
    def self.new_enclose(outer : Environment) : Environment
      Environment.new(outer)
    end

    def initialize(@outer : Environment? = nil)
      @hs = {} of ::String => Object
    end

    def []?(key) : Object?
      obj = @hs[key]?
      outer = @outer
      if obj.nil? && outer
        outer[key]?
      else
        obj
      end
    end

    def []=(key : ::String, value : Object)
      @hs[key] = value
    end
  end
end
