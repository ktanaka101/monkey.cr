require "./ast"
require "./object"

module Crysterpreter::Evaluator
  TRUE  = Crysterpreter::Object::Boolean.new(true)
  FALSE = Crysterpreter::Object::Boolean.new(false)
  NULL  = Crysterpreter::Object::Null.new

  def self.eval(node : Crysterpreter::AST::Node) : Crysterpreter::Object::Object?
    case node
    when Crysterpreter::AST::Program
      eval_program(node)
    when Crysterpreter::AST::ExpressionStatement
      eval(node.expression)
    when Crysterpreter::AST::IntegerLiteral
      Crysterpreter::Object::Integer.new(node.value)
    when Crysterpreter::AST::Boolean
      native_bool_to_boolean_object(node.value)
    when Crysterpreter::AST::PrefixExpression
      right = eval(node.right)
      return nil if right.nil?
      eval_prefix_expression(node.operator, right)
    when Crysterpreter::AST::InfixExpression
      left = eval(node.left)
      right = eval(node.right)
      return nil if left.nil? || right.nil?
      eval_infix_expression(node.operator, left, right)
    when Crysterpreter::AST::BlockStatement
      eval_block_statement(node)
    when Crysterpreter::AST::IfExpression
      eval_if_expressioin(node)
    when Crysterpreter::AST::ReturnStatement
      val = eval(node.return_value)
      return nil if val.nil?
      Crysterpreter::Object::ReturnValue.new(val)
    else
      nil
    end
  end

  # Last statement is return value for eval
  # If return statement exists then return for return statement value
  private def self.eval_program(program : Crysterpreter::AST::Program) : Crysterpreter::Object::Object?
    result = nil

    program.statements.each do |statement|
      result = eval(statement)
      return result.value if result.is_a?(Crysterpreter::Object::ReturnValue)
    end

    result
  end

  # Last statement is return value for eval
  # If return statement exists then return for return statement
  private def self.eval_block_statement(block : Crysterpreter::AST::BlockStatement) : Crysterpreter::Object::Object?
    result = nil

    block.statements.each do |statement|
      result = eval(statement)

      return result if result.is_a?(Crysterpreter::Object::ReturnValue)
    end

    result
  end

  private def self.eval_prefix_expression(operator : String, right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object?
    case operator
    when "!"
      eval_bang_operator_expression(right)
    when "-"
      eval_minus_prefix_operator_expression(right)
    else
      NULL
    end
  end

  private def self.native_bool_to_boolean_object(input : Bool) : Crysterpreter::Object::Object
    input ? TRUE : FALSE
  end

  private def self.eval_bang_operator_expression(right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object
    case right
    when TRUE
      FALSE
    when FALSE
      TRUE
    when NULL
      TRUE
    else
      FALSE
    end
  end

  private def self.eval_minus_prefix_operator_expression(right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object?
    if right.is_a?(Crysterpreter::Object::Integer)
      Crysterpreter::Object::Integer.new(-right.value)
    else
      nil
    end
  end

  private def self.eval_infix_expression(operator : String, left : Crysterpreter::Object::Object, right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object?
    case {left, right}
    when {Crysterpreter::Object::Integer, Crysterpreter::Object::Integer}
      eval_integer_infix_expression(operator, left, right)
    else
      case operator
      when "=="
        native_bool_to_boolean_object(left == right)
      when "!="
        native_bool_to_boolean_object(left != right)
      else
        NULL
      end
    end
  end

  private def self.eval_integer_infix_expression(operator : String, left : Crysterpreter::Object::Object, right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object?
    return nil if !left.is_a?(Crysterpreter::Object::Integer) || !right.is_a?(Crysterpreter::Object::Integer)

    left_val = left.value
    right_val = right.value

    case operator
    when "+"
      Crysterpreter::Object::Integer.new(left_val + right_val)
    when "-"
      Crysterpreter::Object::Integer.new(left_val - right_val)
    when "*"
      Crysterpreter::Object::Integer.new(left_val * right_val)
    when "/"
      Crysterpreter::Object::Integer.new(left_val / right_val)
    when "<"
      native_bool_to_boolean_object(left_val < right_val)
    when ">"
      native_bool_to_boolean_object(left_val > right_val)
    when "=="
      native_bool_to_boolean_object(left_val == right_val)
    when "!="
      native_bool_to_boolean_object(left_val != right_val)
    else
      NULL
    end
  end

  private def self.eval_if_expressioin(ie : Crysterpreter::AST::IfExpression) : Crysterpreter::Object::Object?
    condition = eval(ie.condition)
    return nil if condition.nil?

    alternative = ie.alternative

    if is_truthy(condition)
      eval(ie.consequence)
    elsif alternative
      eval(alternative)
    else
      NULL
    end
  end

  private def self.is_truthy(obj : Crysterpreter::Object::Object) : Bool
    case obj
    when NULL
      false
    when TRUE
      true
    when FALSE
      false
    else
      true
    end
  end
end
