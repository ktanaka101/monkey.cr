require "./ast"
require "./environment"
require "./object"

module Monkey::Evaluator
  TRUE  = Monkey::Object::Boolean.new(true)
  FALSE = Monkey::Object::Boolean.new(false)
  NULL  = Monkey::Object::Null.new

  def self.eval(node : Monkey::AST::Node, env : Monkey::Object::Environment) : Monkey::Object::Object
    case node
    when Monkey::AST::Program
      eval_program(node, env)
    when Monkey::AST::ExpressionStatement
      eval(node.expression, env)
    when Monkey::AST::IntegerLiteral
      Monkey::Object::Integer.new(node.value)
    when Monkey::AST::Boolean
      native_bool_to_boolean_object(node.value)
    when Monkey::AST::PrefixExpression
      right = eval(node.right, env)
      return right if is_error?(right)
      eval_prefix_expression(node.operator, right)
    when Monkey::AST::InfixExpression
      left = eval(node.left, env)
      return left if is_error?(left)
      right = eval(node.right, env)
      return right if is_error?(right)
      eval_infix_expression(node.operator, left, right)
    when Monkey::AST::BlockStatement
      eval_block_statement(node, env)
    when Monkey::AST::IfExpression
      eval_if_expression(node, env)
    when Monkey::AST::ReturnStatement
      val = eval(node.return_value, env)
      return val if is_error?(val)
      Monkey::Object::ReturnValue.new(val)
    when Monkey::AST::LetStatement
      val = eval(node.value, env)
      return val if is_error?(val)
      env[node.name.value] = val
      val
    when Monkey::AST::Identifier
      eval_identifier(node, env)
    else
      new_error("unknown node: #{node}")
    end
  end

  # Last statement is return value for eval
  # If return statement exists then return for return statement value
  private def self.eval_program(program : Monkey::AST::Program, env : Monkey::Object::Environment) : Monkey::Object::Object
    result = nil

    program.statements.each do |statement|
      result = eval(statement, env)

      case result
      when Monkey::Object::ReturnValue
        return result.value
      when Monkey::Object::Error
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
  private def self.eval_block_statement(block : Monkey::AST::BlockStatement, env : Monkey::Object::Environment) : Monkey::Object::Object
    result = nil

    block.statements.each do |statement|
      result = eval(statement, env)

      case result
      when Monkey::Object::ReturnValue, Monkey::Object::Error
        return result
      end
    end

    if result
      result
    else
      new_error("statements empty: #{block}")
    end
  end

  private def self.eval_prefix_expression(operator : String, right : Monkey::Object::Object) : Monkey::Object::Object
    case operator
    when "!"
      eval_bang_operator_expression(right)
    when "-"
      eval_minus_prefix_operator_expression(right)
    else
      new_error("unknown operator: #{operator} #{right.type}")
    end
  end

  private def self.native_bool_to_boolean_object(input : Bool) : Monkey::Object::Object
    input ? TRUE : FALSE
  end

  private def self.eval_bang_operator_expression(right : Monkey::Object::Object) : Monkey::Object::Object
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

  private def self.eval_minus_prefix_operator_expression(right : Monkey::Object::Object) : Monkey::Object::Object
    if right.is_a?(Monkey::Object::Integer)
      Monkey::Object::Integer.new(-right.value)
    else
      new_error("unknown operator: -#{right.type}")
    end
  end

  private def self.eval_infix_expression(operator : String, left : Monkey::Object::Object, right : Monkey::Object::Object) : Monkey::Object::Object
    case {left, right}
    when {Monkey::Object::Integer, Monkey::Object::Integer}
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

  private def self.eval_integer_infix_expression(operator : String, left : Monkey::Object::Object, right : Monkey::Object::Object) : Monkey::Object::Object
    if !left.is_a?(Monkey::Object::Integer) || !right.is_a?(Monkey::Object::Integer)
      return new_error("type mismatch: #{left.type} #{operator} #{right.type}")
    end

    left_val = left.value
    right_val = right.value

    case operator
    when "+"
      Monkey::Object::Integer.new(left_val + right_val)
    when "-"
      Monkey::Object::Integer.new(left_val - right_val)
    when "*"
      Monkey::Object::Integer.new(left_val * right_val)
    when "/"
      Monkey::Object::Integer.new(left_val / right_val)
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

  private def self.eval_if_expression(ie : Monkey::AST::IfExpression, env : Monkey::Object::Environment) : Monkey::Object::Object
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

  private def self.is_truthy(obj : Monkey::Object::Object) : Bool
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

  private def self.new_error(message : String) : Monkey::Object::Error
    Monkey::Object::Error.new(message)
  end

  private def self.is_error?(obj : Monkey::Object::Object) : Bool
    obj.is_a?(Monkey::Object::Error)
  end

  private def self.eval_identifier(node : Monkey::AST::Identifier, env : Monkey::Object::Environment) : Monkey::Object::Object
    env.fetch(node.value, new_error("identifier not found: #{node.value}"))
  end
end
