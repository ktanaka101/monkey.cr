require "./ast"
require "./object/*"

module Monkey::Evaluator
  TRUE  = Object::Boolean.new(true)
  FALSE = Object::Boolean.new(false)
  NULL  = Object::Null.new

  Builtins = {
    "len" => Object::Builtin.new(
      Object::BuiltinFunction.new do |args|
        return new_error("wrong number of arguments. got=#{args.size}, want=1") if args.size != 1

        case arg = args[0]
        when Object::String
          Object::Integer.new(arg.value.size.to_i64)
        when Object::Array
          Object::Integer.new(arg.elements.size.to_i64)
        else
          new_error("argument to 'len' not supported, got #{args[0].type}")
        end
      end
    ),
    "first" => Object::Builtin.new(
      Object::BuiltinFunction.new do |args|
        return new_error("wrong number of arguments. got=#{args.size}, want=1") if args.size != 1
        arr = args[0]
        return new_error("argument to 'first' must be ARRAY, got #{args[0].type}") unless arr.is_a?(Object::Array)
        return NULL if arr.elements.size == 0

        return arr.elements[0]
      end
    ),
    "last" => Object::Builtin.new(
      Object::BuiltinFunction.new do |args|
        return new_error("wrong number of arguments. got=#{args.size}, want=1") if args.size != 1
        arr = args[0]
        return new_error("argument to 'last' must be ARRAY, got #{args[0].type}") unless arr.is_a?(Object::Array)
        return NULL if arr.elements.size == 0

        return arr.elements[-1]
      end
    ),
    "rest" => Object::Builtin.new(
      Object::BuiltinFunction.new do |args|
        return new_error("wrong number of arguments. got=#{args.size}, want=1") if args.size != 1
        arr = args[0]
        return new_error("argument to 'rest' must be ARRAY, got #{args[0].type}") unless arr.is_a?(Object::Array)
        return NULL if arr.elements.size == 0

        Object::Array.new(arr.elements[1..-1])
      end
    ),
    "push" => Object::Builtin.new(
      Object::BuiltinFunction.new do |args|
        return new_error("wrong number of arguments. got=#{args.size}, want=2") if args.size != 2
        arr = args[0]
        return new_error("argument to 'push' must be ARRAY, got #{args[0].type}") unless arr.is_a?(Object::Array)

        Object::Array.new(arr.elements + [args[1]])
      end
    ),
    "puts" => Object::Builtin.new(
      Object::BuiltinFunction.new do |args|
        args.each { |arg| puts arg.inspect }
        NULL
      end
    ),
  }

  def self.eval(node : AST::Node, env : Object::Environment) : Object::Object
    case node
    when AST::Program
      eval_program(node, env)
    when AST::ExpressionStatement
      eval(node.expression, env)
    when AST::IntegerLiteral
      Object::Integer.new(node.value)
    when AST::Boolean
      native_bool_to_boolean_object(node.value)
    when AST::PrefixExpression
      right = eval(node.right, env)
      return right if is_error?(right)
      eval_prefix_expression(node.operator, right)
    when AST::InfixExpression
      left = eval(node.left, env)
      return left if is_error?(left)
      right = eval(node.right, env)
      return right if is_error?(right)
      eval_infix_expression(node.operator, left, right)
    when AST::BlockStatement
      eval_block_statement(node, env)
    when AST::IfExpression
      eval_if_expression(node, env)
    when AST::ReturnStatement
      val = eval(node.return_value, env)
      return val if is_error?(val)
      Object::ReturnValue.new(val)
    when AST::LetStatement
      val = eval(node.value, env)
      return val if is_error?(val)
      env[node.name.value] = val
      NULL
    when AST::Identifier
      eval_identifier(node, env)
    when AST::FunctionLiteral
      params = node.parameters
      body = node.body
      Object::Function.new(params, body, env)
    when AST::CallExpression
      function = eval(node.function, env)
      return function if is_error?(function)
      args = eval_expressions(node.arguments, env)
      return args[0] if args.size == 1 && is_error?(args[0])

      apply_function(function, args)
    when AST::StringLiteral
      Object::String.new(node.value)
    when AST::ArrayLiteral
      elements = eval_expressions(node.elements, env)
      return elements[0] if elements.size == 1 && is_error?(elements[0])
      Object::Array.new(elements)
    when AST::IndexExpression
      left = eval(node.left, env)
      return left if is_error?(left)
      index = eval(node.index, env)
      return index if is_error?(index)
      eval_index_expression(left, index)
    when AST::HashLiteral
      eval_hash_literal(node, env)
    else
      new_error("unknown node: #{node}")
    end
  end

  # Last statement is return value for eval
  # If return statement exists then return for return statement value
  private def self.eval_program(program : AST::Program, env : Object::Environment) : Object::Object
    result = nil

    program.statements.each do |statement|
      result = eval(statement, env)

      case result
      when Object::ReturnValue
        return result.value
      when Object::Error
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
  private def self.eval_block_statement(block : AST::BlockStatement, env : Object::Environment) : Object::Object
    result = nil

    block.statements.each do |statement|
      result = eval(statement, env)

      case result
      when Object::ReturnValue, Object::Error
        return result
      end
    end

    if result
      result
    else
      new_error("statements empty: #{block}")
    end
  end

  private def self.eval_prefix_expression(operator : String, right : Object::Object) : Object::Object
    case operator
    when "!"
      eval_bang_operator_expression(right)
    when "-"
      eval_minus_prefix_operator_expression(right)
    else
      new_error("unknown operator: #{operator} #{right.type}")
    end
  end

  private def self.native_bool_to_boolean_object(input : Bool) : Object::Object
    input ? TRUE : FALSE
  end

  private def self.eval_bang_operator_expression(right : Object::Object) : Object::Object
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

  private def self.eval_minus_prefix_operator_expression(right : Object::Object) : Object::Object
    if right.is_a?(Object::Integer)
      Object::Integer.new(-right.value)
    else
      new_error("unknown operator: -#{right.type}")
    end
  end

  private def self.eval_infix_expression(operator : String, left : Object::Object, right : Object::Object) : Object::Object
    case {left, right}
    when {Object::Integer, Object::Integer}
      eval_integer_infix_expression(operator, left, right)
    when {Object::String, Object::String}
      eval_string_infix_expression(operator, left, right)
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

  private def self.eval_integer_infix_expression(operator : String, left : Object::Integer, right : Object::Integer) : Object::Object
    case operator
    when "+"
      Object::Integer.new(left.value + right.value)
    when "-"
      Object::Integer.new(left.value - right.value)
    when "*"
      Object::Integer.new(left.value * right.value)
    when "/"
      Object::Integer.new(left.value // right.value)
    when "<"
      native_bool_to_boolean_object(left.value < right.value)
    when ">"
      native_bool_to_boolean_object(left.value > right.value)
    when "=="
      native_bool_to_boolean_object(left.value == right.value)
    when "!="
      native_bool_to_boolean_object(left.value != right.value)
    else
      new_error("unknown operator: #{left.type} #{operator} #{right.type}")
    end
  end

  private def self.eval_string_infix_expression(operator : String, left : Object::String, right : Object::String) : Object::Object
    return new_error("unknown operator: #{left.type} #{operator} #{right.type}") unless operator == "+"

    Object::String.new(left.value + right.value)
  end

  private def self.eval_if_expression(ie : AST::IfExpression, env : Object::Environment) : Object::Object
    condition = eval(ie.condition, env)
    return condition if is_error?(condition)

    alternative = ie.alternative

    if is_truthy?(condition)
      eval(ie.consequence, env)
    elsif alternative
      eval(alternative, env)
    else
      NULL
    end
  end

  private def self.is_truthy?(obj : Object::Object) : Bool
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

  private def self.new_error(message : String) : Object::Error
    Object::Error.new(message)
  end

  private def self.is_error?(obj : Object::Object) : Bool
    obj.is_a?(Object::Error)
  end

  private def self.eval_identifier(node : AST::Identifier, env : Object::Environment) : Object::Object
    ident = env[node.value]?
    return ident if ident

    builtin = Builtins[node.value]?
    return builtin if builtin

    new_error("identifier not found: #{node.value}")
  end

  private def self.eval_expressions(exps : Array(AST::Expression), env : Object::Environment) : Array(Object::Object)
    result = [] of Object::Object

    exps.each do |exp|
      evaluated = eval(exp, env)
      return [evaluated] if is_error?(evaluated)
      result << evaluated
    end

    result
  end

  private def self.apply_function(fn : Object::Object, args : Array(Object::Object)) : Object::Object
    case fn
    when Object::Function
      extended_env = extend_function_env(fn, args)
      evaluated = eval(fn.body, extended_env)
      unwrap_return_value(evaluated)
    when Object::Builtin
      fn.fn.call(args)
    else
      return new_error("not a function: #{fn.type}")
    end
  end

  private def self.extend_function_env(fn : Object::Function, args : Array(Object::Object)) : Object::Environment
    env = Object::Environment.new_enclose(fn.env)

    fn.parameters.each_with_index do |param, i|
      env[param.value] = args[i]
    end

    env
  end

  private def self.unwrap_return_value(obj : Object::Object) : Object::Object
    obj.is_a?(Object::ReturnValue) ? obj.value : obj
  end

  private def self.eval_index_expression(left : Object::Object, index : Object::Object) : Object::Object
    case {left, index}
    when {Object::Array, Object::Integer}
      eval_array_index_expression(left, index)
    when {Object::Hash, _}
      eval_hash_index_expression(left, index)
    else
      new_error("index operator not supported: #{left.type}")
    end
  end

  private def self.eval_array_index_expression(array : Object::Array, index : Object::Integer) : Object::Object
    idx = index.value
    max = (array.elements.size - 1).to_i64

    return NULL if idx < 0 || idx > max

    array.elements[idx]
  end

  private def self.eval_hash_literal(node : AST::HashLiteral, env : Object::Environment) : Object::Object
    pairs = {} of Object::HashKey => Object::HashPair

    node.pairs.each do |(key_node, value_node)|
      key = eval(key_node, env)
      return key if is_error?(key)

      value = eval(value_node, env)
      return value if is_error?(value)

      if key.is_a?(Object::Hashable)
        hashed = key.hash_key
        pairs[hashed] = Object::HashPair.new(key, value)
      else
        return new_error("unusable as hash key: #{key.type}")
      end
    end

    Object::Hash.new(pairs)
  end

  private def self.eval_hash_index_expression(hash : Object::Hash, key : Object::Object) : Object::Object
    if key.is_a?(Object::Hashable)
      pair = hash.pairs[key.hash_key]?
      return NULL if pair.nil?

      pair.value
    else
      new_error("unusable as hash key: #{key.type}")
    end
  end
end
