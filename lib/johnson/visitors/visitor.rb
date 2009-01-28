module Johnson
  module Visitors
    class Visitor
      def visit_SourceElements(o)
        o.value.each { |x| x.accept(self) }
      end

      def visit_LexicalScope(o)
        o.right.accept(self)
      end

      %w{
        ArrayLiteral Comma Export FunctionCall Import New ObjectLiteral
        VarStatement LetStatement
      }.each do |type|
        define_method(:"visit_#{type}") do |o|
          o.value.each { |x| x.accept(self) }
        end
      end

      %w{
        Name Number Regexp String
        Break Continue False Null This True
      }.each do |type|
        define_method(:"visit_#{type}") do |o|
        end
      end

      def visit_For(o)
        o.init && o.init.accept(self)
        o.cond && o.cond.accept(self)
        o.update && o.update.accept(self)
        o.body.accept(self)
      end

      def visit_ForIn(o)
        o.in_cond.accept(self)
        o.body.accept(self)
      end

      def visit_Try(o)
        o.cond.accept(self)
        o.b_then && o.b_then.map { |x| x.accept(self) }
        o.b_else && o.b_else.accept(self)
      end

      %w{ Ternary If Catch }.each do |node|
        define_method(:"visit_#{node}") do |o|
          o.cond.accept(self)
          o.b_then && o.b_then.accept(self)
          o.b_else && o.b_else.accept(self)
        end
      end

      ### UNARY NODES ###
      %w{ BitwiseNot Delete Not Parenthesis PostfixDecrement PostfixIncrement
        PrefixDecrement PrefixIncrement Return Throw Typeof UnaryNegative
        UnaryPositive Void
      }.each do |node|
        define_method(:"visit_#{node}") do |o|
          o.value && o.value.accept(self)
        end
      end

      ### FUNCTION NODES ###
      def visit_Function(o)
        o.body.accept(self)
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
          o.left && o.left.accept(self)
          o.right && o.right.accept(self)
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
