require "../spec_helper"
require "../../src/crysterpreter/parser"

record TestLet(T), input : String, expected_identifier : String, expected_value : T
record TestReturn(T), input : String, expected_value : T
record TestPrefix, input : String, operator : String, value : Int64 | Bool
record TestInfix, input : String, left_value : Int64 | Bool, operator : String, right_value : Int64 | Bool
record TestOperatorPrecedence, input : String, expected : String
record TestFunctionParameter, input : String, expected_params : Array(String)

module Crysterpreter::Parser
  describe Parser do
    it "let statements" do
      tests = [
        TestLet(Int32).new("let x = 5", "x", 5),
        TestLet(Int32).new("let x = 5;", "x", 5),
        TestLet(Bool).new("let y = true;", "y", true),
        TestLet(String).new("let foobar = y;", "foobar", "y"),
      ]

      tests.each do |test|
        lexer = Crysterpreter::Lexer::Lexer.new(test.input)
        parser = Parser.new(lexer)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1
        stmt = program.statements[0]
        test_let_statement(stmt, test.expected_identifier)

        if stmt.is_a? Crysterpreter::AST::LetStatement
          val = stmt.value
          test_literal_expression(val, test.expected_value)
        end
      end
    end

    it "return statements" do
      tests = [
        TestReturn(Int32).new("return 5", 5),
        TestReturn(Int32).new("return 5;", 5),
        TestReturn(Bool).new("return true;", true),
        TestReturn(String).new("return y;", "y"),
      ]

      tests.each do |test|
        lexer = Crysterpreter::Lexer::Lexer.new(test.input)
        parser = Parser.new(lexer)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1
        stmt = program.statements[0]
        test_return_statement(stmt, test.expected_value)
      end
    end

    it "string" do
      program = Crysterpreter::AST::Program.new([
        Crysterpreter::AST::LetStatement.new(
          Crysterpreter::Token::Token.new(Crysterpreter::Token::LET, "let"),
          Crysterpreter::AST::Identifier.new(
            Crysterpreter::Token::Token.new(Crysterpreter::Token::IDENT, "myVar"),
            "myVar"
          ),
          Crysterpreter::AST::Identifier.new(
            Crysterpreter::Token::Token.new(Crysterpreter::Token::IDENT, "anotherVar"),
            "anotherVar"
          ),
        ),
      ] of Crysterpreter::AST::Statement)

      program.string.should eq "let myVar = anotherVar;"
    end

    it "identifier expression" do
      inputs = "foobar"

      lexer = Crysterpreter::Lexer::Lexer.new(inputs)
      parser = Parser.new(lexer)
      program = parser.parse_program
      check_parser_errors(parser)

      program.statements.size.should eq 1
      stmt = program.statements[0]

      stmt.should be_a Crysterpreter::AST::ExpressionStatement
      if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
        test_literal_expression(stmt.expression, "foobar")
      end
    end

    it "integer literal" do
      inputs = ["5", "5;"]

      inputs.each do |input|
        lexer = Crysterpreter::Lexer::Lexer.new(input)
        parser = Parser.new(lexer)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1
        stmt = program.statements[0]

        stmt.should be_a Crysterpreter::AST::ExpressionStatement
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          test_literal_expression(stmt.expression, 5)
        end
      end
    end

    it "test boolean" do
      tests = [
        {"true", true},
        {"true;", true},
        {"false;", false},
      ]

      tests.each do |test|
        l = Crysterpreter::Lexer::Lexer.new(test[0])
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1
        stmt = program.statements[0]

        stmt.should be_a Crysterpreter::AST::ExpressionStatement
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          test_literal_expression(stmt.expression, test[1])
        end
      end
    end

    it "parsing prefix expressions" do
      prefix_tests = [
        TestPrefix.new("!5", "!", 5),
        TestPrefix.new("!5;", "!", 5),
        TestPrefix.new("-15;", "-", 15),
        TestPrefix.new("!true;", "!", true),
        TestPrefix.new("!false;", "!", false),
      ]

      prefix_tests.each do |prefix|
        l = Crysterpreter::Lexer::Lexer.new(prefix.input)
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1

        stmt = program.statements[0]
        stmt.should be_a Crysterpreter::AST::ExpressionStatement
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          exp = stmt.expression

          exp.should be_a Crysterpreter::AST::PrefixExpression
          if exp.is_a?(Crysterpreter::AST::PrefixExpression)
            exp.operator.should eq prefix.operator
            test_literal_expression(exp.right, prefix.value)
          end
        end
      end
    end

    it "parsing infix expressions" do
      infix_tests = [
        TestInfix.new("5 + 5", 5, "+", 5),
        TestInfix.new("5 + 5;", 5, "+", 5),
        TestInfix.new("5 - 5;", 5, "-", 5),
        TestInfix.new("5 * 5;", 5, "*", 5),
        TestInfix.new("5 / 5;", 5, "/", 5),
        TestInfix.new("5 > 5;", 5, ">", 5),
        TestInfix.new("5 < 5;", 5, "<", 5),
        TestInfix.new("5 == 5;", 5, "==", 5),
        TestInfix.new("5 != 5;", 5, "!=", 5),
        TestInfix.new("true == true;", true, "==", true),
        TestInfix.new("true != false;", true, "!=", false),
        TestInfix.new("false == false;", false, "==", false),
      ]

      infix_tests.each do |infix|
        l = Crysterpreter::Lexer::Lexer.new(infix.input)
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1

        stmt = program.statements[0]
        stmt.should be_a Crysterpreter::AST::ExpressionStatement
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          test_infix_expression(stmt.expression, infix.left_value, infix.operator, infix.right_value)
        end
      end
    end

    it "operator precedence parsing" do
      tests = {
        TestOperatorPrecedence.new(
          "-a * b",
          "((-a) * b)"
        ),
        TestOperatorPrecedence.new(
          "!-a",
          "(!(-a))"
        ),
        TestOperatorPrecedence.new(
          "a + b + c",
          "((a + b) + c)"
        ),
        TestOperatorPrecedence.new(
          "a + b - c",
          "((a + b) - c)"
        ),
        TestOperatorPrecedence.new(
          "a * b * c",
          "((a * b) * c)"
        ),
        TestOperatorPrecedence.new(
          "a * b / c",
          "((a * b) / c)"
        ),
        TestOperatorPrecedence.new(
          "a + b / c",
          "(a + (b / c))"
        ),
        TestOperatorPrecedence.new(
          "a + b * c + d / e - f",
          "(((a + (b * c)) + (d / e)) - f)"
        ),
        TestOperatorPrecedence.new(
          "3 + 4; -5 * 5",
          "(3 + 4)((-5) * 5)"
        ),
        TestOperatorPrecedence.new(
          "5 > 4 == 3 < 4",
          "((5 > 4) == (3 < 4))"
        ),
        TestOperatorPrecedence.new(
          "5 < 4 != 3 > 4",
          "((5 < 4) != (3 > 4))"
        ),
        TestOperatorPrecedence.new(
          "3 + 4 * 5 == 3 * 1 + 4 * 5",
          "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"
        ),
        TestOperatorPrecedence.new(
          "true",
          "true"
        ),
        TestOperatorPrecedence.new(
          "false",
          "false"
        ),
        TestOperatorPrecedence.new(
          "3 > 5 == false",
          "((3 > 5) == false)"
        ),
        TestOperatorPrecedence.new(
          "3 < 5 == true",
          "((3 < 5) == true)"
        ),
        TestOperatorPrecedence.new(
          "1 + (2 + 3) + 4",
          "((1 + (2 + 3)) + 4)"
        ),
        TestOperatorPrecedence.new(
          "(5 + 5) * 2",
          "((5 + 5) * 2)"
        ),
        TestOperatorPrecedence.new(
          "2 / (5 + 5)",
          "(2 / (5 + 5))"
        ),
        TestOperatorPrecedence.new(
          "-(5 + 5)",
          "(-(5 + 5))"
        ),
        TestOperatorPrecedence.new(
          "!(true == true)",
          "(!(true == true))"
        ),
        TestOperatorPrecedence.new(
          "a + add(b * c) + d",
          "((a + add((b * c))) + d)"
        ),
        TestOperatorPrecedence.new(
          "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
          "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
        ),
        TestOperatorPrecedence.new(
          "add(a + b + c * d / f  + g)",
          "add((((a + b) + ((c * d) / f)) + g))"
        ),
      }

      tests.each do |test|
        l = Crysterpreter::Lexer::Lexer.new(test.input)
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        actual = program.string
        actual.should eq test.expected
      end
    end

    it "if expression" do
      input = "if (x < y) { x }"

      l = Crysterpreter::Lexer::Lexer.new(input)
      parser = Parser.new(l)
      program = parser.parse_program
      check_parser_errors(parser)

      program.statements.size.should eq 1

      stmt = program.statements[0]
      stmt.should be_a Crysterpreter::AST::ExpressionStatement
      if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
        exp = stmt.expression
        exp.should be_a Crysterpreter::AST::IfExpression
        if exp.is_a?(Crysterpreter::AST::IfExpression)
          test_infix_expression(exp.condition, "x", "<", "y")
          exp.consequence.statements.size.should eq 1
          consequence = exp.consequence.statements[0]

          consequence.should be_a Crysterpreter::AST::ExpressionStatement
          if consequence.is_a?(Crysterpreter::AST::ExpressionStatement)
            test_indentifier(consequence.expression, "x")

            exp.alternative.should be_nil
          end
        end
      end
    end

    it "if else expression" do
      inputs = ["if (x < y) { x } else { y }", "if (x < y) { x; } else { y; }"]

      inputs.each do |input|
        l = Crysterpreter::Lexer::Lexer.new(input)
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1

        stmt = program.statements[0]
        stmt.should be_a Crysterpreter::AST::ExpressionStatement
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          exp = stmt.expression
          exp.should be_a Crysterpreter::AST::IfExpression
          if exp.is_a?(Crysterpreter::AST::IfExpression)
            test_infix_expression(exp.condition, "x", "<", "y")
            exp.consequence.statements.size.should eq 1
            consequence = exp.consequence.statements[0]

            consequence.should be_a Crysterpreter::AST::ExpressionStatement
            if consequence.is_a?(Crysterpreter::AST::ExpressionStatement)
              test_indentifier(consequence.expression, "x")
            end

            alt = exp.alternative
            alt.should be_a Crysterpreter::AST::BlockStatement
            if alt.is_a?(Crysterpreter::AST::BlockStatement)
              alt.statements.size.should eq 1
              alternative = alt.statements[0]

              alternative.should be_a Crysterpreter::AST::ExpressionStatement
              if alternative.is_a?(Crysterpreter::AST::ExpressionStatement)
                test_indentifier(alternative.expression, "y")
              end
            end
          end
        end
      end
    end

    it "function literal parsing" do
      inputs = ["fn(x, y) { x + y }", "fn(x, y) { x + y; }"]

      inputs.each do |input|
        l = Crysterpreter::Lexer::Lexer.new(input)
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        program.statements.size.should eq 1

        stmt = program.statements[0]
        stmt.should be_a Crysterpreter::AST::ExpressionStatement
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          exp = stmt.expression
          exp.should be_a Crysterpreter::AST::FunctionLiteral
          if exp.is_a?(Crysterpreter::AST::FunctionLiteral)
            exp.parameters.size.should eq 2

            test_literal_expression(exp.parameters[0], "x")
            test_literal_expression(exp.parameters[1], "y")

            exp.body.statements.size.should eq 1
            body_stmt = exp.body.statements[0]
            body_stmt.should be_a Crysterpreter::AST::ExpressionStatement
            if body_stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
              test_infix_expression(body_stmt.expression, "x", "+", "y")
            end
          end
        end
      end
    end

    it "function parameter parsing" do
      tests = {
        TestFunctionParameter.new("fn() {};", [] of String),
        TestFunctionParameter.new("fn(x) {};", ["x"]),
        TestFunctionParameter.new("fn(x, y, z) {};", ["x", "y", "z"]),
      }

      tests.each do |test|
        l = Crysterpreter::Lexer::Lexer.new(test.input)
        parser = Parser.new(l)
        program = parser.parse_program
        check_parser_errors(parser)

        stmt = program.statements[0]
        if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
          function = stmt.expression

          function.should be_a Crysterpreter::AST::FunctionLiteral
          if function.is_a?(Crysterpreter::AST::FunctionLiteral)
            function.parameters.size.should eq test.expected_params.size

            test.expected_params.each_with_index do |ident, i|
              test_literal_expression(function.parameters[i], ident)
            end
          end
        end
      end
    end

    it "call expression parsing" do
      input = "add(1, 2 * 3, 4 + 5);"

      l = Crysterpreter::Lexer::Lexer.new(input)
      parser = Parser.new(l)
      program = parser.parse_program
      check_parser_errors(parser)

      program.statements.size.should eq 1

      stmt = program.statements[0]
      stmt.should be_a Crysterpreter::AST::ExpressionStatement
      if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
        exp = stmt.expression
        exp.should be_a Crysterpreter::AST::CallExpression
        if exp.is_a?(Crysterpreter::AST::CallExpression)
          test_indentifier(exp.function, "add")
          exp.arguments.size.should eq 3
          test_literal_expression(exp.arguments[0], 1)
          test_infix_expression(exp.arguments[1], 2, "*", 3)
          test_infix_expression(exp.arguments[2], 4, "+", 5)
        end
      end
    end
  end
end

def check_parser_errors(parser : Crysterpreter::Parser::Parser)
  errors = parser.errors
  return if errors.size == 0

  puts("parser has #{errors.size} errors")
  errors.each do |error|
    puts "parser error: #{error}"
  end

  "test".should eq "fail."
end

def test_let_statement(stmt : Crysterpreter::AST::Statement, name : String)
  stmt.should be_a Crysterpreter::AST::LetStatement
  if stmt.is_a?(Crysterpreter::AST::LetStatement)
    stmt.token_literal.should eq "let"
    stmt.name.value.should eq name
    stmt.name.token_literal.should eq name
  end
end

def test_return_statement(stmt : Crysterpreter::AST::Statement, return_value)
  stmt.should be_a Crysterpreter::AST::ReturnStatement
  if stmt.is_a?(Crysterpreter::AST::ReturnStatement)
    stmt.token_literal.should eq "return"
    test_literal_expression(stmt.return_value, return_value)
  end
end

def test_integer_literal(exp, value : Int64)
  exp.should be_a Crysterpreter::AST::IntegerLiteral
  if exp.is_a?(Crysterpreter::AST::IntegerLiteral)
    exp.value.should eq value
    exp.token_literal.should eq value.to_s
  end
end

def test_indentifier(exp, value : String)
  exp.should be_a Crysterpreter::AST::Identifier
  if exp.is_a?(Crysterpreter::AST::Identifier)
    exp.value.should eq value
    exp.token_literal.should eq value
  end
end

def test_boolean_literal(exp, value : Bool)
  exp.should be_a Crysterpreter::AST::Boolean
  if exp.is_a?(Crysterpreter::AST::Boolean)
    exp.value.should eq value
    exp.token_literal.should eq value.to_s
  end
end

def test_literal_expression(exp, expected)
  case expected
  when Int32
    test_integer_literal(exp, Int64.new(expected))
  when Int64
    test_integer_literal(exp, expected)
  when String
    test_indentifier(exp, expected)
  when Bool
    test_boolean_literal(exp, expected)
  else
    expected.should eq "type of exp not handled."
  end
end

def test_infix_expression(exp, left, operator, right)
  exp.should be_a Crysterpreter::AST::InfixExpression
  if exp.is_a?(Crysterpreter::AST::InfixExpression)
    test_literal_expression(exp.left, left)
    exp.operator.should eq operator
    test_literal_expression(exp.right, right)
  end
end
