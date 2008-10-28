module Johnson
  module Visitors
    class EnumeratingVisitor
      attr_accessor :block
      def initialize(block)
        @block = block
      end

      def visit_SourceElements(o)
        block.call(o)
        o.value.each { |x| x.accept(self) }
        self
      end

      def visit_LexicalScope(o)
        block.call(o)
        o.right.accept(self)
        self
      end

      %w{
        ArrayLiteral Comma Export FunctionCall Import New ObjectLiteral
        VarStatement LetStatement
      }.each do |type|
        define_method(:"visit_#{type}") do |o|
          block.call(o)
          o.value.each { |x| x.accept(self) }
          self
        end
      end

      %w{ Name Number Regexp String }.each do |type|
        define_method(:"visit_#{type}") do |o|
          block.call(o)
          self
        end
      end

      %w{ Break Continue False Null This True }.each do |type|
        define_method(:"visit_#{type}") do |o|
          block.call(o)
          self
        end
      end

      def visit_For(o)
        block.call(o)
        o.init && o.init.accept(self)
        o.cond && o.cond.accept(self)
        o.update && o.update.accept(self)
        o.body.accept(self)
        self
      end

      def visit_ForIn(o)
        block.call(o)
        o.in_cond.accept(self)
        o.body.accept(self)
        self
      end

      def visit_Try(o)
        block.call(o)
        o.cond.accept(self)
        o.b_then && o.b_then.map { |x| x.accept(self) }
        o.b_else && o.b_else.accept(self)
        self
      end

      %w{ Ternary If Catch }.each do |node|
        define_method(:"visit_#{node}") do |o|
          block.call(o)
          o.cond.accept(self)
          o.b_then && o.b_then.accept(self)
          o.b_else && o.b_else.accept(self)
          self
        end
      end
      ### UNARY NODES ###
      %w{ BitwiseNot Delete Not Parenthesis PostfixDecrement PostfixIncrement
        PrefixDecrement PrefixIncrement Return Throw Typeof UnaryNegative
        UnaryPositive Void
      }.each do |node|
        define_method(:"visit_#{node}") do |o|
          block.call(o)
          o.value && o.value.accept(self)
          self
        end
      end

      ### FUNCTION NODES ###
      def visit_Function(o)
        block.call(o)
        o.body.accept(self)
        self
      end

      ### BINARY NODES ###
      %w{ And AssignExpr BracketAccess Case Default DoWhile DotAccessor Equal
        GetterProperty GreaterThan GreaterThanOrEqual In InstanceOf Label
        LessThan LessThanOrEqual NotEqual OpAdd OpAddEqual OpBitAnd
        OpBitAndEqual OpBitOr OpBitOrEqual OpBitXor OpBitXorEqual OpDivide
        OpDivideEqual OpEqual OpLShift OpLShiftEqual OpMod OpModEqual
        OpMultiply OpMultiplyEqual OpRShift OpRShiftEqual OpSubtract
        OpSubtractEqual OpURShift OpURShiftEqual Or Property SetterProperty
        StrictEqual StrictNotEqual Switch While With
      }.each do |node|
        define_method(:"visit_#{node}") do |o|
          block.call(o)
          o.left && o.left.accept(self)
          o.right && o.right.accept(self)
          self
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
