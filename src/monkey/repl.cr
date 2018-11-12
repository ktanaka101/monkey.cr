require "./lexer"
require "./token"
require "./parser"
require "./evaluator"
require "./environment"

module Monkey::REPL
  PROMPT = ">> "

  def self.start
    env = Monkey::Object::Environment.new

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

      evaluated = Monkey::Evaluator.eval(program, env)
      next if evaluated.nil?

      puts "#{evaluated.inspect}\n"
    end
  end

  private def self.print_parse_errors(errors : Array(String))
    errors.each do |error|
      puts "\t#{error}\n"
    end
  end
end
