require "../spec_helper"
require "../../src/crysterpreter/evaluator"
require "../../src/crysterpreter/lexer"
require "../../src/crysterpreter/object"
require "../../src/crysterpreter/parser"

record TestExpression(T), input : String, expected : T
alias TestInteger = TestExpression(Int64)

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

macro define_test_object(object_type, expected_type)
  def test_{{object_type.id.underscore}}_object(object : Crysterpreter::Object::Object, expected : {{expected_type}})
    object.should be_a Crysterpreter::Object::{{object_type}}
    if object.is_a?(Crysterpreter::Object::{{object_type}})
      object.value.should eq expected
    end
  end
end

define_test_object Integer, Int64