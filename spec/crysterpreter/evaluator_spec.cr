require "../spec_helper"
require "../../src/crysterpreter/evaluator"
require "../../src/crysterpreter/lexer"
require "../../src/crysterpreter/object"
require "../../src/crysterpreter/parser"

record TestInteger, input : String, expected : Int64

module Crysterpreter::Evaluator
  describe Evaluator do
    it "eval integer expression" do
      tests = [
        TestInteger.new("5", 5),
        TestInteger.new("10", 10),
      ]

      tests.each do |test|
        evaluated = test_eval(test.input)
        evaluated.should_not be_nil
        if evaluated
          test_integer_object(evaluated, test.expected)
        end
      end
    end
  end
end

def test_eval(input : String) : Crysterpreter::Object::Object?
  l = Crysterpreter::Lexer::Lexer.new(input)
  p = Crysterpreter::Parser::Parser.new(l)
  program = p.parse_program

  Crysterpreter::Evaluator.eval(program)
end

def test_integer_object(object : Crysterpreter::Object::Object, expected : Int64)
  object.should be_a Crysterpreter::Object::Integer
  if object.is_a?(Crysterpreter::Object::Integer)
    object.value.should eq expected
  end
end
