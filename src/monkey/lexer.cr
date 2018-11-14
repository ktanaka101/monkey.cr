require "./token"

module Monkey::Lexer
  class Lexer
    def initialize(@input : String, @position : Int32 = 0, @read_position : Int32 = 0, @ch : Char | Int32 = 0)
      read_char
    end

    def read_char
      if @read_position >= @input.size
        @ch = 0
      else
        @ch = @input[@read_position]
      end

      @position = @read_position
      @read_position += 1
    end

    def peek_char : Char | Int32
      if @read_position >= @input.size
        0
      else
        @input[@read_position]
      end
    end

    def read_identifier : String
      position = @position
      ch = @ch
      while ch.is_a?(Char) && self.class.is_letter?(ch)
        read_char
        ch = @ch
      end

      @input[position...@position]
    end

    def read_number : String
      position = @position
      ch = @ch
      while ch.is_a?(Char) && self.class.is_digit?(ch)
        read_char
        ch = @ch
      end

      @input[position...@position]
    end

    def read_string : String
      position = @position + 1
      loop do
        read_char
        break if @ch == '"' || @ch == 0
      end

      @input[position...@position]
    end

    def self.is_letter?(ch : Char) : Bool
      ('a'..'z').includes?(ch) || ('A'..'Z').includes?(ch) || ch == '_' || ch == '!' || ch == '?'
    end

    def self.is_digit?(ch : Char) : Bool
      ('0'..'9').includes?(ch)
    end

    def skip_whitespace
      while @ch == ' ' || @ch == '\t' || @ch == '\n' || @ch == '\r'
        read_char
      end
    end

    def next_token : Token::Token
      skip_whitespace

      ch = @ch
      tok = if ch.is_a?(Int32)
              Token::Token.new(Token::EOF, "")
            else
              str = ch.to_s
              case ch
              when '='
                if peek_char == '='
                  read_char
                  Token::Token.new(Token::EQ, (str + @ch.to_s))
                else
                  Token::Token.new(Token::ASSIGN, str)
                end
              when '+'
                Token::Token.new(Token::PLUS, str)
              when '-'
                Token::Token.new(Token::MINUS, str)
              when '!'
                if peek_char == '='
                  read_char
                  Token::Token.new(Token::NOT_EQ, (str + @ch.to_s))
                else
                  Token::Token.new(Token::BANG, str)
                end
              when '*'
                Token::Token.new(Token::ASTERISK, str)
              when '/'
                Token::Token.new(Token::SLASH, str)
              when '<'
                Token::Token.new(Token::LT, str)
              when '>'
                Token::Token.new(Token::GT, str)
              when ','
                Token::Token.new(Token::COMMA, str)
              when ';'
                Token::Token.new(Token::SEMICOLON, str)
              when '('
                Token::Token.new(Token::LPAREN, str)
              when ')'
                Token::Token.new(Token::RPAREN, str)
              when '{'
                Token::Token.new(Token::LBRACE, str)
              when '}'
                Token::Token.new(Token::RBRACE, str)
              when '"'
                Token::Token.new(Token::STRING, read_string)
              else
                if self.class.is_letter?(ch)
                  literal = read_identifier
                  return Token::Token.new(Token.lookup_ident(literal), literal)
                elsif self.class.is_digit?(ch)
                  return Token::Token.new(Token::INT, read_number)
                else
                  Token::Token.new(Token::ILLEGAL, str)
                end
              end
            end

      read_char
      tok
    end
  end
end
