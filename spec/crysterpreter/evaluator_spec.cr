require "../spec_helper"
require "../../src/crysterpreter/evaluator"
require "../../src/crysterpreter/lexer"
require "../../src/crysterpreter/object"
require "../../src/crysterpreter/parser"

module Crysterpreter::Evaluator
  describe Evaluator do
    describe "eval integer expression" do
      {
        {"5", 5_i64},
        {"10", 10_i64},
        {"-5", -5_i64},
        {"-10", -10_i64},
        {"5 + 5 + 5 + 5 - 10", 10_i64},
        {"2 * 2 * 2 * 2 * 2", 32_i64},
        {"-50 + 100 + -50", 0_i64},
        {"5 * 2 + 10", 20_i64},
        {"5 + 2 * 10", 25_i64},
        {"20 + 2 * -10", 0_i64},
        {"50 / 2 * 2 + 10", 60_i64},
        {"2 * (5 + 10)", 30_i64},
        {"3 * 3 * 3 + 10", 37_i64},
        {"3 * (3 * 3) + 10", 37_i64},
        {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50_i64},
      }.each do |input, expected|
        it "for #{input}" do
          evaluated = test_eval(input)
          evaluated.should_not be_nil
          if evaluated
            test_integer_object(evaluated, expected)
          end
        end
      end
    end

    describe "eval boolean expression" do
      {
        {"true", true},
        {"false", false},
        {"1 < 2", true},
        {"1 > 2", false},
        {"1 < 1", false},
        {"1 > 1", false},
        {"1 == 1", true},
        {"1 != 1", false},
        {"1 == 2", false},
        {"1 != 2", true},
        {"true == true", true},
        {"false == false", true},
        {"true == false", false},
        {"true != false", true},
        {"false != true", true},
        {"(1 < 2) == true", true},
        {"(1 < 2) == false", false},
        {"(1 > 2) == true", false},
        {"(1 > 2) == false", true},
      }.each do |input, expected|
        it "for #{input}" do
          evaluated = test_eval(input)
          evaluated.should_not be_nil
          if evaluated
            test_boolean_object(evaluated, expected)
          end
        end
      end
    end

    describe "bang operator" do
      {
        {"!true", false},
        {"!false", true},
        {"!5", false},
        {"!!true", true},
        {"!!false", false},
        {"!!5", true},
      }.each do |input, expected|
        it "for #{input}" do
          evaluated = test_eval(input)
          evaluated.should_not be_nil
          if evaluated
            test_boolean_object(evaluated, expected)
          end
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
define_test_object Boolean, Bool
