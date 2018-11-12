require "./object"

module Monkey::Object
  class Environment
    def initialize
      @hs = {} of String => Monkey::Object::Object
    end

    forward_missing_to @hs
  end
end
