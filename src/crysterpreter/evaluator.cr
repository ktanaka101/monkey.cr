require "./ast"
require "./object"

module Crysterpreter::Evaluator
  def self.eval(node : Crysterpreter::AST::Node) : Crysterpreter::Object::Object?
    case node
    when Crysterpreter::AST::Program
      eval_statements(node.statements)
    when Crysterpreter::AST::ExpressionStatement
      eval(node.expression)
    when Crysterpreter::AST::IntegerLiteral
      Crysterpreter::Object::Integer.new(node.value)
    else
      nil
    end
  end

  private def self.eval_statements(stmts : Array(Crysterpreter::AST::Statement)) : Crysterpreter::Object::Object?
    stmts.map { |statement|
      eval(statement)
    }.last
  end
end
