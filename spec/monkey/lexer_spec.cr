require "../spec_helper"

module Monkey::Lexer
  describe Lexer do
    it "next token" do
      tests = {
        {Monkey::Token::LET, "let"}, {Monkey::Token::IDENT, "five"}, {Monkey::Token::ASSIGN, "="}, {Monkey::Token::INT, "5"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::LET, "let"}, {Monkey::Token::IDENT, "ten"}, {Monkey::Token::ASSIGN, "="}, {Monkey::Token::INT, "10"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::LET, "let"}, {Monkey::Token::IDENT, "add"}, {Monkey::Token::ASSIGN, "="},
        {Monkey::Token::FUNCTION, "fn"}, {Monkey::Token::LPAREN, "("}, {Monkey::Token::IDENT, "x"}, {Monkey::Token::COMMA, ","}, {Monkey::Token::IDENT, "y"}, {Monkey::Token::RPAREN, ")"},
        {Monkey::Token::LBRACE, "{"}, {Monkey::Token::IDENT, "x"}, {Monkey::Token::PLUS, "+"}, {Monkey::Token::IDENT, "y"}, {Monkey::Token::SEMICOLON, ";"}, {Monkey::Token::RBRACE, "}"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::LET, "let"}, {Monkey::Token::IDENT, "result"}, {Monkey::Token::ASSIGN, "="},
        {Monkey::Token::IDENT, "add"}, {Monkey::Token::LPAREN, "("}, {Monkey::Token::IDENT, "five"}, {Monkey::Token::COMMA, ","}, {Monkey::Token::IDENT, "ten"}, {Monkey::Token::RPAREN, ")"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::BANG, "!"}, {Monkey::Token::MINUS, "-"}, {Monkey::Token::SLASH, "/"}, {Monkey::Token::ASTERISK, "*"}, {Monkey::Token::INT, "5"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::INT, "5"}, {Monkey::Token::LT, "<"}, {Monkey::Token::INT, "10"}, {Monkey::Token::GT, ">"}, {Monkey::Token::INT, "5"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::IF, "if"}, {Monkey::Token::LPAREN, "("}, {Monkey::Token::INT, "5"}, {Monkey::Token::LT, "<"}, {Monkey::Token::INT, "10"}, {Monkey::Token::RPAREN, ")"},
        {Monkey::Token::LBRACE, "{"}, {Monkey::Token::RETURN, "return"}, {Monkey::Token::TRUE, "true"}, {Monkey::Token::SEMICOLON, ";"}, {Monkey::Token::RBRACE, "}"},
        {Monkey::Token::ELSE, "else"}, {Monkey::Token::LBRACE, "{"}, {Monkey::Token::RETURN, "return"}, {Monkey::Token::FALSE, "false"}, {Monkey::Token::SEMICOLON, ";"}, {Monkey::Token::RBRACE, "}"},
        {Monkey::Token::INT, "10"}, {Monkey::Token::EQ, "=="}, {Monkey::Token::INT, "10"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::INT, "10"}, {Monkey::Token::NOT_EQ, "!="}, {Monkey::Token::INT, "9"}, {Monkey::Token::SEMICOLON, ";"},
        {Monkey::Token::STRING, "foobar"},
        {Monkey::Token::STRING, "foo bar"},
        {Monkey::Token::EOF, ""},
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
        "foobar"
        "foo bar"
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
