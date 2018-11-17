module Monkey::Token
  alias TokenType = String

  struct Token
    property type : TokenType, literal : String

    def initialize(@type : TokenType, @literal : String)
    end

    def to_s
      "#{@type}: #{@literal}"
    end
  end

  ILLEGAL = "ILLEGAL"
  EOF     = "EOF"

  # 識別子 + リテラル
  IDENT  = "IDENT"
  INT    = "INT"
  STRING = "STRING"

  # 演算子
  ASSIGN   = "="
  PLUS     = "+"
  MINUS    = "-"
  BANG     = "!"
  ASTERISK = "*"
  SLASH    = "/"
  EQ       = "=="
  NOT_EQ   = "!="

  LT = "<"
  GT = ">"

  # デリミタ
  COMMA     = ","
  SEMICOLON = ";"

  LPAREN   = "("
  RPAREN   = ")"
  LBRACE   = "{"
  RBRACE   = "}"
  LBRACKET = "["
  RBRACKET = "]"

  # キーワード
  FUNCTION = "FUNCTION"
  LET      = "LET"
  TRUE     = "TRUE"
  FALSE    = "FALSE"
  IF       = "IF"
  ELSE     = "ELSE"
  RETURN   = "RETURN"

  KEYWORDS = Hash(String, TokenType){
    "fn"     => FUNCTION,
    "let"    => LET,
    "true"   => TRUE,
    "false"  => FALSE,
    "if"     => IF,
    "else"   => ELSE,
    "return" => RETURN,
  }

  def self.lookup_ident(ident : String) : TokenType
    if KEYWORDS.has_key?(ident)
      KEYWORDS[ident]
    else
      IDENT
    end
  end
end
