require "./lexer"
require "./token"
require "./parser"

module Crysterpreter::REPL
  PROMPT = ">> "

  def self.start
    while true
      print PROMPT

      line = gets
      break if line.nil?

      lexer = Lexer::Lexer.new(line)
      parser = Parser::Parser.new(lexer)

      program = parser.parse_program
      if parser.errors.size != 0
        print_parse_errors(parser.errors)
        next
      end

      puts "#{program.string}\n"
    end
  end

  private def self.print_parse_errors(errors : Array(String))
    errors.each do |error|
      puts "\t#{error}\n"
    end
  end
end
