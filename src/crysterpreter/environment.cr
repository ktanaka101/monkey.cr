require "./object"

module Crysterpreter::Object
  class Environment
    def initialize
      @hs = {} of String => Crysterpreter::Object::Object
    end

    forward_missing_to @hs
  end
end
