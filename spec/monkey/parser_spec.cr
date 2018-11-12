require "../spec_helper"
require "../../src/monkey/parser"

module Monkey::Parser
  describe Parser do
    describe "let statements" do
      {
        {"let x = 5", "x", 5},
        {"let x = 5;", "x", 5},
        {"let y = true;", "y", true},
        {"let foobar = y;", "foobar", "y"},
      }.each do |input, expected_identifier, expected_value|
        it "for #{input}" do
          lexer = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(lexer)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1
          stmt = program.statements[0]
          test_let_statement(stmt, expected_identifier)

          if stmt.is_a? Monkey::AST::LetStatement
            val = stmt.value
            test_literal_expression(val, expected_value)
          end
        end
      end
    end

    describe "return statements" do
      {
        {"return 5", 5},
        {"return 5;", 5},
        {"return true;", true},
        {"return y;", "y"},
      }.each do |input, expected|
        it "for #{input}" do
          lexer = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(lexer)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1
          stmt = program.statements[0]
          test_return_statement(stmt, expected)
        end
      end
    end

    it "string" do
      program = Monkey::AST::Program.new([
        Monkey::AST::LetStatement.new(
          Monkey::Token::Token.new(Monkey::Token::LET, "let"),
          Monkey::AST::Identifier.new(
            Monkey::Token::Token.new(Monkey::Token::IDENT, "myVar"),
            "myVar"
          ),
          Monkey::AST::Identifier.new(
            Monkey::Token::Token.new(Monkey::Token::IDENT, "anotherVar"),
            "anotherVar"
          ),
        ),
      ] of Monkey::AST::Statement)

      program.string.should eq "let myVar = anotherVar;"
    end

    it "identifier expression" do
      inputs = "foobar"

      lexer = Monkey::Lexer::Lexer.new(inputs)
      parser = Parser.new(lexer)
      program = parser.parse_program
      check_parser_errors(parser)

      program.statements.size.should eq 1
      stmt = program.statements[0]

      stmt.should be_a Monkey::AST::ExpressionStatement
      if stmt.is_a?(Monkey::AST::ExpressionStatement)
        test_literal_expression(stmt.expression, "foobar")
      end
    end

    describe "integer literal" do
      {
        {"5", 5},
        {"5;", 5},
      }.each do |input, expected|
        it "for #{input}" do
          lexer = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(lexer)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1
          stmt = program.statements[0]

          stmt.should be_a Monkey::AST::ExpressionStatement
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            test_literal_expression(stmt.expression, expected)
          end
        end
      end
    end

    describe "test boolean" do
      {
        {"true", true},
        {"true;", true},
        {"false;", false},
      }.each do |input, expected|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1
          stmt = program.statements[0]

          stmt.should be_a Monkey::AST::ExpressionStatement
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            test_literal_expression(stmt.expression, expected)
          end
        end
      end
    end

    describe "parsing prefix expressions" do
      {
        {"!5", "!", 5},
        {"!5;", "!", 5},
        {"-15;", "-", 15},
        {"!true;", "!", true},
        {"!false;", "!", false},
      }.each do |input, expected_operator, expected_value|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1

          stmt = program.statements[0]
          stmt.should be_a Monkey::AST::ExpressionStatement
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            exp = stmt.expression

            exp.should be_a Monkey::AST::PrefixExpression
            if exp.is_a?(Monkey::AST::PrefixExpression)
              exp.operator.should eq expected_operator
              test_literal_expression(exp.right, expected_value)
            end
          end
        end
      end
    end

    describe "parsing infix expressions" do
      {
        {"5 + 5", 5, "+", 5},
        {"5 + 5;", 5, "+", 5},
        {"5 - 5;", 5, "-", 5},
        {"5 * 5;", 5, "*", 5},
        {"5 / 5;", 5, "/", 5},
        {"5 > 5;", 5, ">", 5},
        {"5 < 5;", 5, "<", 5},
        {"5 == 5;", 5, "==", 5},
        {"5 != 5;", 5, "!=", 5},
        {"true == true;", true, "==", true},
        {"true != false;", true, "!=", false},
        {"false == false;", false, "==", false},
      }.each do |input, expected_left, expected_operator, expected_right|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1

          stmt = program.statements[0]
          stmt.should be_a Monkey::AST::ExpressionStatement
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            test_infix_expression(stmt.expression, expected_left, expected_operator, expected_right)
          end
        end
      end
    end

    describe "operator precedence parsing" do
      {
        {
          "-a * b",
          "((-a) * b)",
        },
        {
          "!-a",
          "(!(-a))",
        },
        {
          "a + b + c",
          "((a + b) + c)",
        },
        {
          "a + b - c",
          "((a + b) - c)",
        },
        {
          "a * b * c",
          "((a * b) * c)",
        },
        {
          "a * b / c",
          "((a * b) / c)",
        },
        {
          "a + b / c",
          "(a + (b / c))",
        },
        {
          "a + b * c + d / e - f",
          "(((a + (b * c)) + (d / e)) - f)",
        },
        {
          "3 + 4; -5 * 5",
          "(3 + 4)((-5) * 5)",
        },
        {
          "5 > 4 == 3 < 4",
          "((5 > 4) == (3 < 4))",
        },
        {
          "5 < 4 != 3 > 4",
          "((5 < 4) != (3 > 4))",
        },
        {
          "3 + 4 * 5 == 3 * 1 + 4 * 5",
          "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))",
        },
        {
          "true",
          "true",
        },
        {
          "false",
          "false",
        },
        {
          "3 > 5 == false",
          "((3 > 5) == false)",
        },
        {
          "3 < 5 == true",
          "((3 < 5) == true)",
        },
        {
          "1 + (2 + 3) + 4",
          "((1 + (2 + 3)) + 4)",
        },
        {
          "(5 + 5) * 2",
          "((5 + 5) * 2)",
        },
        {
          "2 / (5 + 5)",
          "(2 / (5 + 5))",
        },
        {
          "-(5 + 5)",
          "(-(5 + 5))",
        },
        {
          "!(true == true)",
          "(!(true == true))",
        },
        {
          "a + add(b * c) + d",
          "((a + add((b * c))) + d)",
        },
        {
          "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
          "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))",
        },
        {
          "add(a + b + c * d / f  + g)",
          "add((((a + b) + ((c * d) / f)) + g))",
        },
      }.each do |input, expected|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          actual = program.string
          actual.should eq expected
        end
      end
    end

    it "if expression" do
      input = "if (x < y) { x }"

      l = Monkey::Lexer::Lexer.new(input)
      parser = Parser.new(l)
      program = parser.parse_program
      check_parser_errors(parser)

      program.statements.size.should eq 1

      stmt = program.statements[0]
      stmt.should be_a Monkey::AST::ExpressionStatement
      if stmt.is_a?(Monkey::AST::ExpressionStatement)
        exp = stmt.expression
        exp.should be_a Monkey::AST::IfExpression
        if exp.is_a?(Monkey::AST::IfExpression)
          test_infix_expression(exp.condition, "x", "<", "y")
          exp.consequence.statements.size.should eq 1
          consequence = exp.consequence.statements[0]

          consequence.should be_a Monkey::AST::ExpressionStatement
          if consequence.is_a?(Monkey::AST::ExpressionStatement)
            test_indentifier(consequence.expression, "x")

            exp.alternative.should be_nil
          end
        end
      end
    end

    describe "if else expression" do
      {
        "if (x < y) { x } else { y }",
        "if (x < y) { x; } else { y; }",
      }.each do |input|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1

          stmt = program.statements[0]
          stmt.should be_a Monkey::AST::ExpressionStatement
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            exp = stmt.expression
            exp.should be_a Monkey::AST::IfExpression
            if exp.is_a?(Monkey::AST::IfExpression)
              test_infix_expression(exp.condition, "x", "<", "y")
              exp.consequence.statements.size.should eq 1
              consequence = exp.consequence.statements[0]

              consequence.should be_a Monkey::AST::ExpressionStatement
              if consequence.is_a?(Monkey::AST::ExpressionStatement)
                test_indentifier(consequence.expression, "x")
              end

              alt = exp.alternative
              alt.should be_a Monkey::AST::BlockStatement
              if alt.is_a?(Monkey::AST::BlockStatement)
                alt.statements.size.should eq 1
                alternative = alt.statements[0]

                alternative.should be_a Monkey::AST::ExpressionStatement
                if alternative.is_a?(Monkey::AST::ExpressionStatement)
                  test_indentifier(alternative.expression, "y")
                end
              end
            end
          end
        end
      end
    end

    describe "function literal parsing" do
      {
        "fn(x, y) { x + y }",
        "fn(x, y) { x + y; }",
      }.each do |input|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          program.statements.size.should eq 1

          stmt = program.statements[0]
          stmt.should be_a Monkey::AST::ExpressionStatement
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            exp = stmt.expression
            exp.should be_a Monkey::AST::FunctionLiteral
            if exp.is_a?(Monkey::AST::FunctionLiteral)
              exp.parameters.size.should eq 2

              test_literal_expression(exp.parameters[0], "x")
              test_literal_expression(exp.parameters[1], "y")

              exp.body.statements.size.should eq 1
              body_stmt = exp.body.statements[0]
              body_stmt.should be_a Monkey::AST::ExpressionStatement
              if body_stmt.is_a?(Monkey::AST::ExpressionStatement)
                test_infix_expression(body_stmt.expression, "x", "+", "y")
              end
            end
          end
        end
      end
    end

    describe "function parameter parsing" do
      {
        {"fn() {};", [] of String},
        {"fn(x) {};", ["x"]},
        {"fn(x, y, z) {};", ["x", "y", "z"]},
      }.each do |input, expected_params|
        it "for #{input}" do
          l = Monkey::Lexer::Lexer.new(input)
          parser = Parser.new(l)
          program = parser.parse_program
          check_parser_errors(parser)

          stmt = program.statements[0]
          if stmt.is_a?(Monkey::AST::ExpressionStatement)
            function = stmt.expression

            function.should be_a Monkey::AST::FunctionLiteral
            if function.is_a?(Monkey::AST::FunctionLiteral)
              function.parameters.size.should eq expected_params.size

              expected_params.each_with_index do |ident, i|
                test_literal_expression(function.parameters[i], ident)
              end
            end
          end
        end
      end
    end

    it "call expression parsing" do
      input = "add(1, 2 * 3, 4 + 5);"

      l = Monkey::Lexer::Lexer.new(input)
      parser = Parser.new(l)
      program = parser.parse_program
      check_parser_errors(parser)

      program.statements.size.should eq 1

      stmt = program.statements[0]
      stmt.should be_a Monkey::AST::ExpressionStatement
      if stmt.is_a?(Monkey::AST::ExpressionStatement)
        exp = stmt.expression
        exp.should be_a Monkey::AST::CallExpression
        if exp.is_a?(Monkey::AST::CallExpression)
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

def check_parser_errors(parser : Monkey::Parser::Parser)
  errors = parser.errors
  return if errors.size == 0

  puts("parser has #{errors.size} errors")
  errors.each do |error|
    puts "parser error: #{error}"
  end

  "test".should eq "fail."
end

def test_let_statement(stmt : Monkey::AST::Statement, name : String)
  stmt.should be_a Monkey::AST::LetStatement
  if stmt.is_a?(Monkey::AST::LetStatement)
    stmt.token_literal.should eq "let"
    stmt.name.value.should eq name
    stmt.name.token_literal.should eq name
  end
end

def test_return_statement(stmt : Monkey::AST::Statement, return_value)
  stmt.should be_a Monkey::AST::ReturnStatement
  if stmt.is_a?(Monkey::AST::ReturnStatement)
    stmt.token_literal.should eq "return"
    test_literal_expression(stmt.return_value, return_value)
  end
end

def test_integer_literal(exp, value : Int64)
  exp.should be_a Monkey::AST::IntegerLiteral
  if exp.is_a?(Monkey::AST::IntegerLiteral)
    exp.value.should eq value
    exp.token_literal.should eq value.to_s
  end
end

def test_indentifier(exp, value : String)
  exp.should be_a Monkey::AST::Identifier
  if exp.is_a?(Monkey::AST::Identifier)
    exp.value.should eq value
    exp.token_literal.should eq value
  end
end

def test_boolean_literal(exp, value : Bool)
  exp.should be_a Monkey::AST::Boolean
  if exp.is_a?(Monkey::AST::Boolean)
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
  exp.should be_a Monkey::AST::InfixExpression
  if exp.is_a?(Monkey::AST::InfixExpression)
    test_literal_expression(exp.left, left)
    exp.operator.should eq operator
    test_literal_expression(exp.right, right)
  end
end
