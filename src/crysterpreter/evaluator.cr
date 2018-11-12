require "./ast"
require "./environment"
require "./object"

module Crysterpreter::Evaluator
  TRUE  = Crysterpreter::Object::Boolean.new(true)
  FALSE = Crysterpreter::Object::Boolean.new(false)
  NULL  = Crysterpreter::Object::Null.new

  def self.eval(node : Crysterpreter::AST::Node, env : Crysterpreter::Object::Environment) : Crysterpreter::Object::Object
    case node
    when Crysterpreter::AST::Program
      eval_program(node, env)
    when Crysterpreter::AST::ExpressionStatement
      eval(node.expression, env)
    when Crysterpreter::AST::IntegerLiteral
      Crysterpreter::Object::Integer.new(node.value)
    when Crysterpreter::AST::Boolean
      native_bool_to_boolean_object(node.value)
    when Crysterpreter::AST::PrefixExpression
      right = eval(node.right, env)
      return right if is_error?(right)
      eval_prefix_expression(node.operator, right)
    when Crysterpreter::AST::InfixExpression
      left = eval(node.left, env)
      return left if is_error?(left)
      right = eval(node.right, env)
      return right if is_error?(right)
      eval_infix_expression(node.operator, left, right)
    when Crysterpreter::AST::BlockStatement
      eval_block_statement(node, env)
    when Crysterpreter::AST::IfExpression
      eval_if_expressioin(node, env)
    when Crysterpreter::AST::ReturnStatement
      val = eval(node.return_value, env)
      return val if is_error?(val)
      Crysterpreter::Object::ReturnValue.new(val)
    when Crysterpreter::AST::LetStatement
      val = eval(node.value, env)
      return val if is_error?(val)
      env[node.name.value] = val
      val
    when Crysterpreter::AST::Identifier
      eval_identifier(node, env)
    else
      new_error("unknown node: #{node}")
    end
  end

  # Last statement is return value for eval
  # If return statement exists then return for return statement value
  private def self.eval_program(program : Crysterpreter::AST::Program, env : Crysterpreter::Object::Environment) : Crysterpreter::Object::Object
    result = nil

    program.statements.each do |statement|
      result = eval(statement, env)

      case result
      when Crysterpreter::Object::ReturnValue
        return result.value
      when Crysterpreter::Object::Error
        return result
      end
    end

    if result
      result
    else
      new_error("statements empty: #{program}")
    end
  end

  # Last statement is return value for eval
  # If return statement exists then return for return statement
  private def self.eval_block_statement(block : Crysterpreter::AST::BlockStatement, env : Crysterpreter::Object::Environment) : Crysterpreter::Object::Object
    result = nil

    block.statements.each do |statement|
      result = eval(statement, env)

      case result
      when Crysterpreter::Object::ReturnValue, Crysterpreter::Object::Error
        return result
      end
    end

    if result
      result
    else
      new_error("statements empty: #{block}")
    end
  end

  private def self.eval_prefix_expression(operator : String, right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object
    case operator
    when "!"
      eval_bang_operator_expression(right)
    when "-"
      eval_minus_prefix_operator_expression(right)
    else
      new_error("unknown operator: #{operator} #{right.type}")
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

  private def self.eval_minus_prefix_operator_expression(right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object
    if right.is_a?(Crysterpreter::Object::Integer)
      Crysterpreter::Object::Integer.new(-right.value)
    else
      new_error("unknown operator: -#{right.type}")
    end
  end

  private def self.eval_infix_expression(operator : String, left : Crysterpreter::Object::Object, right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object
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
        if left.type != right.type
          new_error("type mismatch: #{left.type} #{operator} #{right.type}")
        else
          new_error("unknown operator: #{left.type} #{operator} #{right.type}")
        end
      end
    end
  end

  private def self.eval_integer_infix_expression(operator : String, left : Crysterpreter::Object::Object, right : Crysterpreter::Object::Object) : Crysterpreter::Object::Object
    if !left.is_a?(Crysterpreter::Object::Integer) || !right.is_a?(Crysterpreter::Object::Integer)
      return new_error("type mismatch: #{left.type} #{operator} #{right.type}")
    end

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
      new_error("unknown operator: #{left.type} #{operator} #{right.type}")
    end
  end

  private def self.eval_if_expressioin(ie : Crysterpreter::AST::IfExpression, env : Crysterpreter::Object::Environment) : Crysterpreter::Object::Object
    condition = eval(ie.condition, env)
    return condition if is_error?(condition)

    alternative = ie.alternative

    if is_truthy(condition)
      eval(ie.consequence, env)
    elsif alternative
      eval(alternative, env)
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

  private def self.new_error(message : String) : Crysterpreter::Object::Error
    Crysterpreter::Object::Error.new(message)
  end

  private def self.is_error?(obj : Crysterpreter::Object::Object) : Bool
    obj.is_a?(Crysterpreter::Object::Error)
  end

  private def self.eval_identifier(node : Crysterpreter::AST::Identifier, env : Crysterpreter::Object::Environment) : Crysterpreter::Object::Object
    env.fetch(node.value, new_error("identifier not found: #{node.value}"))
  end
end
