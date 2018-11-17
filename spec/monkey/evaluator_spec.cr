require "../spec_helper"
require "../../src/monkey/evaluator"
require "../../src/monkey/lexer"
require "../../src/monkey/object/*"
require "../../src/monkey/parser"

module Monkey::Evaluator
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
          test_integer_object(test_eval(input), expected)
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
          test_boolean_object(test_eval(input), expected)
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
          test_boolean_object(test_eval(input), expected)
        end
      end
    end

    describe "if else expression" do
      {
        {"if (true) { 10 }", 10_i64},
        {"if (false) { 10 }", nil},
        {"if (1) { 10 }", 10_i64},
        {"if ( 1 < 2 ) { 10 }", 10_i64},
        {"if ( 1 > 2 ) { 10 }", nil},
        {"if ( 1 > 2 ) { 10 } else { 20 }", 20_i64},
        {"if ( 1 < 2 ) { 10 } else { 20 }", 10_i64},
      }.each do |input, expected|
        it "for #{input}" do
          test_object(test_eval(input), expected)
        end
      end
    end

    describe "return statements" do
      {
        {"return 10;", 10_i64},
        {"return 10; 9;", 10_i64},
        {"return 2 * 5; 9;", 10_i64},
        {"9; return 2 * 5; 9;", 10_i64},
        {
          %(
            if (10 > 1) {
              if (10 > 1) {
                return 10;
              }
            }

            retrun 1;
          ), 10_i64,
        },
      }.each do |input, expected|
        it "for #{input}" do
          test_integer_object(test_eval(input), expected)
        end
      end
    end

    describe "error handling" do
      {
        {"5 + true;", "type mismatch: INTEGER + BOOLEAN"},
        {"5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"},
        {"-true", "unknown operator: -BOOLEAN"},
        {"true + false;", "unknown operator: BOOLEAN + BOOLEAN"},
        {"5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"},
        {"if (10 > 1 ) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"},
        {
          %(
            if (10 > 1) {
              if (10 > 1) {
                return true + false;
              }
              return 1;
            }
          ),
          "unknown operator: BOOLEAN + BOOLEAN",
        },
        {"foobar", "identifier not found: foobar"},
        {
          %("Hello" - "World"),
          "unknown operator: STRING - STRING",
        },
      }.each do |input, expected|
        it "for #{input}" do
          evaluated = test_eval(input)

          evaluated.should be_a Monkey::Object::Error
          if evaluated.is_a?(Monkey::Object::Error)
            evaluated.message.should eq expected
          end
        end
      end
    end

    describe "let statements" do
      {
        {"let a = 5; a;", 5_i64},
        {"let a = 5 * 5; a;", 25_i64},
        {"let a = 5; let b = a; b;", 5_i64},
        {"let a = 5; let b = a; let c = a + b + 5; c;", 15_i64},
      }.each do |input, expected|
        it "for #{input}" do
          test_integer_object(test_eval(input), expected)
        end
      end
    end

    describe "function object" do
      {
        {"fn(x) { x + 2; };", 1, "x", "(x + 2)"},
      }.each do |input, expected_params_size, expected_params, expected_body|
        it "for #{input}" do
          evaluated = test_eval(input)
          evaluated.should be_a Monkey::Object::Function
          if evaluated.is_a?(Monkey::Object::Function)
            evaluated.parameters.size.should eq expected_params_size
            evaluated.parameters[0].string.should eq expected_params
            evaluated.body.string.should eq expected_body
          end
        end
      end
    end

    describe "function application" do
      {
        {"let identity = fn(x) { x; }; identity(5);", 5_i64},
        {"let identity = fn(x) { return x; }; identity(5);", 5_i64},
        {"let double = fn(x) { x * 2; }; double(5);", 10_i64},
        {"let add = fn(x, y) { x + y; }; add(5, 5);", 10_i64},
        {"let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20_i64},
        {"fn(x) { x; }(5)", 5_i64},
        {
          %(
            let add = fn(a, b) { a + b };
            let sub = fn(a, b) { a - b };
            let apply_func = fn(a, b, func) { func(a, b) };
            apply_func(2, 2, add);
          ), 4_i64,
        },
        {
          %(
            let add = fn(a, b) { a + b };
            let sub = fn(a, b) { a - b };
            let apply_func = fn(a, b, func) { func(a, b) };
            apply_func(10, 2, sub);
          ), 8_i64,
        },
      }.each do |input, expected|
        it "for #{input}" do
          test_integer_object(test_eval(input), expected)
        end
      end
    end

    describe "closures" do
      {
        {
          %(
            let new_addr = fn(x) {
              fn(y) { x + y};
            }

            let addTwo = new_addr(2);
            addTwo(2);
          ), 4_i64,
        },
      }.each do |input, expected|
        it "for #{input}" do
          test_integer_object(test_eval(input), expected)
        end
      end
    end

    describe "string literal" do
      {
        {
          %("Hello World!"),
          "Hello World!",
        },
      }.each do |input, expected|
        it "for #{input}" do
          test_string_object(test_eval(input), expected)
        end
      end
    end

    describe "string concatenation" do
      {
        {
          %("Hello" + " " + "World!"),
          "Hello World!",
        },
      }.each do |input, expected|
        it "for #{input}" do
          test_string_object(test_eval(input), expected)
        end
      end
    end

    describe "builtin functions" do
      {
        {
          %(len("")), 0_i64
        },
        {
          %(len("four")), 4_i64
        },
        {
          %(len("hello world")), 11_i64,
        },
        {
          %(len(1)), TestError.new("argument to 'len' not supported, got INTEGER")
        },
        {
          %(len("one", "two")), TestError.new("wrong number of arguments. got=2, want=1")
        }
      }.each do |input, expected|
        it "for #{input}" do
          evaluated = test_eval(input)
          test_object(evaluated, expected)
        end
      end
    end
  end
end

record TestError, message : String

def test_object(object : Monkey::Object::Object, expected)
  case expected
  when Bool
    test_boolean_object(object, expected)
  when Int64
    test_integer_object(object, expected)
  when String
    test_string_object(object, expected)
  when Nil
    test_null_object(object)
  when TestError
    test_error_object(object, expected)
  else
    "it test is ".should be_false
  end
end

def test_eval(input : String) : Monkey::Object::Object
  l = Monkey::Lexer::Lexer.new(input)
  p = Monkey::Parser::Parser.new(l)
  program = p.parse_program
  env = Monkey::Object::Environment.new

  evaluated = Monkey::Evaluator.eval(program, env)
  evaluated
end

macro define_test_object(object_type, expected_type)
  def test_{{object_type.id.underscore}}_object(object : Monkey::Object::Object, expected : {{expected_type}})
    object.should be_a Monkey::Object::{{object_type}}
    if object.is_a?(Monkey::Object::{{object_type}})
      object.value.should eq expected
    end
  end
end

define_test_object Integer, Int64
define_test_object Boolean, Bool
define_test_object String, String

def test_null_object(object : Monkey::Object::Object)
  object.should be_a Monkey::Object::Null
end

def test_error_object(object : Monkey::Object::Object, expected : TestError)
  object.should be_a Monkey::Object::Error
  if object.is_a?(Monkey::Object::Error)
    object.message.should eq expected.message
  end
end
