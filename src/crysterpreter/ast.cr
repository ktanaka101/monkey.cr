require "./token.cr"

module Crysterpreter::AST
  abstract class Node
    abstract def token_literal : String
    abstract def string : String
  end

  abstract class Statement < Node
    abstract def statement_node
  end

  abstract class Expression < Node
    abstract def expression_node
  end

  class Program
    getter statements

    def initialize(@statements : Array(Statement))
    end

    def token_literal : String
      if @statements.size > 0
        @statements[0].token_literal
      else
        ""
      end
    end

    def string
      @statements.map(&.string).join
    end
  end

  class ExpressionStatement < Statement
    getter expression

    def initialize(@token : Token::Token, @expression : Expression)
    end

    def statement_node
    end

    def token_literal
      @token.literal
    end

    def string
      expression = @expression
      unless expression.nil?
        expression.string
      else
        ""
      end
    end
  end

  class LetStatement < Statement
    property token, name, value

    def initialize(@token : Token::Token, @name : Identifier, @value : Expression? = nil)
    end

    def statement_node
    end

    def token_literal
      @token.literal
    end

    def string
      out = "#{token_literal} #{@name.string} = "

      value = @value
      out += value.string unless value.nil?
      out += ";"

      out
    end
  end

  class ReturnStatement < Statement
    def initialize(@token : Token::Token, @return_value : Expression? = nil)
    end

    def statement_node
    end

    def token_literal
      @token.literal
    end

    def string
      out = "#{token_literal} "

      return_value = @return_value
      out += return_value.string unless return_value.nil?
      out += ";"

      out
    end
  end

  class Identifier < Expression
    getter token, value

    def initialize(@token : Token::Token, @value : String)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      @value
    end
  end

  class IntegerLiteral < Expression
    getter token : Token::Token, value : Int64

    def initialize(@token, @value)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      @token.literal
    end
  end

  class PrefixExpression < Expression
    getter token : Token::Token, operator : String, right : Expression

    def initialize(@token, @operator, @right)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      "(#{@operator}#{@right.string})"
    end
  end

  class InfixExpression < Expression
    getter token : Token::Token, left : Expression, operator : String, right : Expression

    def initialize(@token, @left, @operator, @right)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      "(#{@left.string} #{@operator} #{@right.string})"
    end
  end

  class Boolean < Expression
    getter token : Token::Token, value : Bool

    def initialize(@token, @value)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      @token.literal
    end
  end

  class IfExpression < Expression
    getter token : Token::Token, condition : Expression, consequence : BlockStatement, alternative : BlockStatement?

    def initialize(@token, @condition, @consequence, @alternative)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      s = "if#{@condition.string} #{@consequence.string}"

      alternative = @alternative
      if alternative
        s += "else #{alternative.string}"
      end

      s
    end
  end

  class BlockStatement < Statement
    getter token : Token::Token, statements : Array(Statement)

    def initialize(@token, @statements)
    end

    def statement_node
    end

    def token_literal
      @token.literal
    end

    def string
      @statements.each_with_object("") do |stmt, str|
        str += stmt.string
      end
    end
  end

  class FunctionLiteral < Expression
    getter token : Token::Token, parameters : Array(Identifier), body : BlockStatement

    def initialize(@token, @parameters, @body)
    end

    def expression_node
    end

    def token_literal
      @token.literal
    end

    def string
      "#{token_literal}(#{@parameters.map(&.string).join(", ")}) #{@body.string}"
    end
  end
end
