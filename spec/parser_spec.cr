require "spec"
require "../src/crysterpreter/parser.cr"

record TestIdentifier, expected_identifier : String
record TestPrefix, input : String, operator : String, value : Int64 | Bool
record TestInfix, input : String, left_value : Int64 | Bool, operator : String, right_value : Int64 | Bool
record TestOperatorPrecedence, input : String, expected : String

describe Crysterpreter::Parser do
  it "let statements" do
    inputs = <<-STRING
      let x = 5;
      let y = 10;
      let foobar = 838383;
    STRING

    lexer = Crysterpreter::Lexer::Lexer.new(inputs)
    parser = Crysterpreter::Parser::Parser.new(lexer)

    program = parser.parse_program
    check_parser_errors(parser)
    program.should_not be_nil
    program.statements.size.should eq 3

    tests = [
      TestIdentifier.new("x"),
      TestIdentifier.new("y"),
      TestIdentifier.new("foobar"),
    ]

    tests.each_with_index do |test, i|
      test_let_statement(program.statements[i], test.expected_identifier)
    end
  end

  it "return statements" do
    inputs = <<-STRING
      return 5;
      return 10;
      return 993322;
    STRING

    lexer = Crysterpreter::Lexer::Lexer.new(inputs)
    parser = Crysterpreter::Parser::Parser.new(lexer)

    program = parser.parse_program
    check_parser_errors(parser)
    program.should_not be_nil
    program.statements.size.should eq 3

    program.statements.each do |stmt|
      stmt.should_not be_nil
      stmt.should be_a Crysterpreter::AST::ReturnStatement
      stmt.token_literal.should eq "return"
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
    parser = Crysterpreter::Parser::Parser.new(lexer)
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
    input = "5;"

    lexer = Crysterpreter::Lexer::Lexer.new(input)
    parser = Crysterpreter::Parser::Parser.new(lexer)
    program = parser.parse_program
    check_parser_errors(parser)

    program.statements.size.should eq 1
    stmt = program.statements[0]

    stmt.should be_a Crysterpreter::AST::ExpressionStatement
    if stmt.is_a?(Crysterpreter::AST::ExpressionStatement)
      test_literal_expression(stmt.expression, 5)
    end
  end

  it "test boolean" do
    tests = [
      {"true;", true},
      {"false;", false},
    ]

    tests.each do |test|
      l = Crysterpreter::Lexer::Lexer.new(test[0])
      parser = Crysterpreter::Parser::Parser.new(l)
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
      TestPrefix.new("!5;", "!", 5),
      TestPrefix.new("-15;", "-", 15),
      TestPrefix.new("!true;", "!", true),
      TestPrefix.new("!false;", "!", false),
    ]

    prefix_tests.each do |prefix|
      l = Crysterpreter::Lexer::Lexer.new(prefix.input)
      parser = Crysterpreter::Parser::Parser.new(l)
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
      parser = Crysterpreter::Parser::Parser.new(l)
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
    }

    tests.each do |test|
      l = Crysterpreter::Lexer::Lexer.new(test.input)
      parser = Crysterpreter::Parser::Parser.new(l)
      program = parser.parse_program
      check_parser_errors(parser)

      actual = program.string
      actual.should eq test.expected
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
