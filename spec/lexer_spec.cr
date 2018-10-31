require "./spec_helper"

record TestToken, expected_type : Crysterpreter::Token::TokenType, expected_literal : String

describe Crysterpreter do
  it "TestNextToken" do
    tests = [
      TestToken.new(Crysterpreter::Token::LET, "let"),
      TestToken.new(Crysterpreter::Token::IDENT, "five"),
      TestToken.new(Crysterpreter::Token::ASSIGN, "="),
      TestToken.new(Crysterpreter::Token::INT, "5"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::LET, "let"),
      TestToken.new(Crysterpreter::Token::IDENT, "ten"),
      TestToken.new(Crysterpreter::Token::ASSIGN, "="),
      TestToken.new(Crysterpreter::Token::INT, "10"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::LET, "let"),
      TestToken.new(Crysterpreter::Token::IDENT, "add"),
      TestToken.new(Crysterpreter::Token::ASSIGN, "="),
      TestToken.new(Crysterpreter::Token::FUNCTION, "fn"),
      TestToken.new(Crysterpreter::Token::LPAREN, "("),
      TestToken.new(Crysterpreter::Token::IDENT, "x"),
      TestToken.new(Crysterpreter::Token::COMMA, ","),
      TestToken.new(Crysterpreter::Token::IDENT, "y"),
      TestToken.new(Crysterpreter::Token::RPAREN, ")"),
      TestToken.new(Crysterpreter::Token::LBRACE, "{"),
      TestToken.new(Crysterpreter::Token::IDENT, "x"),
      TestToken.new(Crysterpreter::Token::PLUS, "+"),
      TestToken.new(Crysterpreter::Token::IDENT, "y"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::RBRACE, "}"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::LET, "let"),
      TestToken.new(Crysterpreter::Token::IDENT, "result"),
      TestToken.new(Crysterpreter::Token::ASSIGN, "="),
      TestToken.new(Crysterpreter::Token::IDENT, "add"),
      TestToken.new(Crysterpreter::Token::LPAREN, "("),
      TestToken.new(Crysterpreter::Token::IDENT, "five"),
      TestToken.new(Crysterpreter::Token::COMMA, ","),
      TestToken.new(Crysterpreter::Token::IDENT, "ten"),
      TestToken.new(Crysterpreter::Token::RPAREN, ")"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::BANG, "!"),
      TestToken.new(Crysterpreter::Token::MINUS, "-"),
      TestToken.new(Crysterpreter::Token::SLASH, "/"),
      TestToken.new(Crysterpreter::Token::ASTERISK, "*"),
      TestToken.new(Crysterpreter::Token::INT, "5"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::INT, "5"),
      TestToken.new(Crysterpreter::Token::LT, "<"),
      TestToken.new(Crysterpreter::Token::INT, "10"),
      TestToken.new(Crysterpreter::Token::GT, ">"),
      TestToken.new(Crysterpreter::Token::INT, "5"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::IF, "if"),
      TestToken.new(Crysterpreter::Token::LPAREN, "("),
      TestToken.new(Crysterpreter::Token::INT, "5"),
      TestToken.new(Crysterpreter::Token::LT, "<"),
      TestToken.new(Crysterpreter::Token::INT, "10"),
      TestToken.new(Crysterpreter::Token::RPAREN, ")"),
      TestToken.new(Crysterpreter::Token::LBRACE, "{"),
      TestToken.new(Crysterpreter::Token::RETURN, "return"),
      TestToken.new(Crysterpreter::Token::TRUE, "true"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::RBRACE, "}"),
      TestToken.new(Crysterpreter::Token::ELSE, "else"),
      TestToken.new(Crysterpreter::Token::LBRACE, "{"),
      TestToken.new(Crysterpreter::Token::RETURN, "return"),
      TestToken.new(Crysterpreter::Token::FALSE, "false"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::RBRACE, "}"),
      TestToken.new(Crysterpreter::Token::INT, "10"),
      TestToken.new(Crysterpreter::Token::EQ, "=="),
      TestToken.new(Crysterpreter::Token::INT, "10"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::INT, "10"),
      TestToken.new(Crysterpreter::Token::NOT_EQ, "!="),
      TestToken.new(Crysterpreter::Token::INT, "9"),
      TestToken.new(Crysterpreter::Token::SEMICOLON, ";"),
      TestToken.new(Crysterpreter::Token::EOF, ""),
    ]

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

    l = Crysterpreter::Lexer::Lexer.new(input)

    tests.each_with_index do |tt, i|
      tok = l.next_token

      tok.type.should eq(tt.expected_type)
      tok.literal.should eq(tt.expected_literal)
    end
  end
end
