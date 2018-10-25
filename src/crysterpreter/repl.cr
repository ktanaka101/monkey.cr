require "./lexer.cr"
require "./token.cr"

module Crysterpreter::REPL
  PROMPT = ">> "

  def self.start
    while true
      print PROMPT

      line = gets
      break if line.nil?

      lexer = Lexer::Lexer.new(line)

      while true
        token = lexer.next_token
        break if token.type == Token::EOF

        puts token
      end
    end
  end
end
