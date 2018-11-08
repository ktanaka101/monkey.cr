require "../spec_helper"

record TestToken, expected_type : Crysterpreter::Token::TokenType, expected_literal : String

module Crysterpreter::Lexer
  describe Lexer do
    it "next token" do
      tests = {
        {Crysterpreter::Token::LET, "let"}, {Crysterpreter::Token::IDENT, "five"}, {Crysterpreter::Token::ASSIGN, "="}, {Crysterpreter::Token::INT, "5"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::LET, "let"}, {Crysterpreter::Token::IDENT, "ten"}, {Crysterpreter::Token::ASSIGN, "="}, {Crysterpreter::Token::INT, "10"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::LET, "let"}, {Crysterpreter::Token::IDENT, "add"}, {Crysterpreter::Token::ASSIGN, "="},
        {Crysterpreter::Token::FUNCTION, "fn"}, {Crysterpreter::Token::LPAREN, "("}, {Crysterpreter::Token::IDENT, "x"}, {Crysterpreter::Token::COMMA, ","}, {Crysterpreter::Token::IDENT, "y"}, {Crysterpreter::Token::RPAREN, ")"},
        {Crysterpreter::Token::LBRACE, "{"}, {Crysterpreter::Token::IDENT, "x"}, {Crysterpreter::Token::PLUS, "+"}, {Crysterpreter::Token::IDENT, "y"}, {Crysterpreter::Token::SEMICOLON, ";"}, {Crysterpreter::Token::RBRACE, "}"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::LET, "let"}, {Crysterpreter::Token::IDENT, "result"}, {Crysterpreter::Token::ASSIGN, "="},
        {Crysterpreter::Token::IDENT, "add"}, {Crysterpreter::Token::LPAREN, "("}, {Crysterpreter::Token::IDENT, "five"}, {Crysterpreter::Token::COMMA, ","}, {Crysterpreter::Token::IDENT, "ten"}, {Crysterpreter::Token::RPAREN, ")"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::BANG, "!"}, {Crysterpreter::Token::MINUS, "-"}, {Crysterpreter::Token::SLASH, "/"}, {Crysterpreter::Token::ASTERISK, "*"}, {Crysterpreter::Token::INT, "5"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::INT, "5"}, {Crysterpreter::Token::LT, "<"}, {Crysterpreter::Token::INT, "10"}, {Crysterpreter::Token::GT, ">"}, {Crysterpreter::Token::INT, "5"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::IF, "if"}, {Crysterpreter::Token::LPAREN, "("}, {Crysterpreter::Token::INT, "5"}, {Crysterpreter::Token::LT, "<"}, {Crysterpreter::Token::INT, "10"}, {Crysterpreter::Token::RPAREN, ")"},
        {Crysterpreter::Token::LBRACE, "{"}, {Crysterpreter::Token::RETURN, "return"}, {Crysterpreter::Token::TRUE, "true"}, {Crysterpreter::Token::SEMICOLON, ";"}, {Crysterpreter::Token::RBRACE, "}"},
        {Crysterpreter::Token::ELSE, "else"}, {Crysterpreter::Token::LBRACE, "{"}, {Crysterpreter::Token::RETURN, "return"}, {Crysterpreter::Token::FALSE, "false"}, {Crysterpreter::Token::SEMICOLON, ";"}, {Crysterpreter::Token::RBRACE, "}"},
        {Crysterpreter::Token::INT, "10"}, {Crysterpreter::Token::EQ, "=="}, {Crysterpreter::Token::INT, "10"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::INT, "10"}, {Crysterpreter::Token::NOT_EQ, "!="}, {Crysterpreter::Token::INT, "9"}, {Crysterpreter::Token::SEMICOLON, ";"},
        {Crysterpreter::Token::EOF, ""},
      }

      input = <<-STRING
        let five = 5;
        let ten = 10;

        let add = fn(x, y) {
          x + y;
        };

        let result = add(five, ten);
        !-/*5;
        5 < 10 > 5;

        if(5 < 10) {
          return true;
        } else {
          return false;
        }

        10 == 10;
        10 != 9;
      STRING

      l = Lexer.new(input)

      tests.each_with_index do |(expected_type, expected_literal), i|
        tok = l.next_token

        tok.type.should eq(expected_type)
        tok.literal.should eq(expected_literal)
      end
    end
  end
end
