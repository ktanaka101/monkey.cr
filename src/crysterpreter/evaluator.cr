require "./ast"
require "./object"

module Crysterpreter::Evaluator
  TRUE  = Crysterpreter::Object::Boolean.new(true)
  FALSE = Crysterpreter::Object::Boolean.new(false)

  def self.eval(node : Crysterpreter::AST::Node) : Crysterpreter::Object::Object?
    case node
    when Crysterpreter::AST::Program
      eval_statements(node.statements)
    when Crysterpreter::AST::ExpressionStatement
      eval(node.expression)
    when Crysterpreter::AST::IntegerLiteral
      Crysterpreter::Object::Integer.new(node.value)
    when Crysterpreter::AST::Boolean
      node.value ? TRUE : FALSE
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
