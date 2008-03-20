module Johnson
  module Visitors
    class SexpVisitor
      def visit_SourceElements(o)
        o.value.map { |x| x.accept(self) }
      end

      def visit_VarStatement(o)
        [:var, o.value.map { |x| x.accept(self) }]
      end

      def visit_Comma(o)
        [:comma, o.value.map { |x| x.accept(self) }]
      end

      def visit_ObjectLiteral(o)
        [:object, o.value.map { |x| x.accept(self) }]
      end

      def visit_ArrayLiteral(o)
        [:array, o.value.map { |x| x.accept(self) }]
      end

      def visit_New(o)
        [:new, o.value.map { |x| x.accept(self) }]
      end

      def visit_FunctionCall(o)
        [:function_call, o.value.map { |x| x.accept(self) }]
      end

      def visit_Name(o)
        [:name, o.value]
      end

      def visit_Parenthesis(o)
        [:paren, o.value.accept(self)]
      end

      def visit_PostfixIncrement(o)
        [:postfix_inc, o.value.accept(self)]
      end

      def visit_PrefixIncrement(o)
        [:prefix_inc, o.value.accept(self)]
      end

      def visit_PostfixDecrement(o)
        [:postfix_dec, o.value.accept(self)]
      end

      def visit_PrefixDecrement(o)
        [:prefix_dec, o.value.accept(self)]
      end

      def visit_Number(o)
        [:lit, o.value]
      end

      def visit_Regexp(o)
        [:lit, o.value]
      end

      def visit_String(o)
        [:str, o.value]
      end

      def visit_Null(o)
        [:nil]
      end

      def visit_True(o)
        [:true]
      end

      def visit_False(o)
        [:false]
      end

      def visit_This(o)
        [:this]
      end

      def visit_Semicolon(o)
        [:semicolon]
      end

      ### UNARY NODES ###
      def visit_Throw(o)
        [:throw, o.value.accept(self)]
      end

      ### FUNCTION NODES ###
      def visit_Function(o)
        [:func_expr, o.name, o.arguments, o.body.accept(self)]
      end

      ### BINARY NODES ###
      {
        'Property'        => :property,
        'GetterProperty'  => :getter,
        'SetterProperty'  => :setter,
        'OpEqual'         => :op_equal,
        'OpMultiplyEqual' => :op_multiply_equal,
        'OpAddEqual'      => :op_add_equal,
        'OpSubtractEqual' => :op_subtract_equal,
        'OpDivideEqual'   => :op_divide_equal,
        'OpLShiftEqual'   => :op_lshift_equal,
        'OpRShiftEqual'   => :op_rshift_equal,
        'OpURShiftEqual'  => :op_urshift_equal,
        'OpBitAndEqual'   => :op_bitand_equal,
        'OpBitXorEqual'   => :op_bitxor_equal,
        'OpBitOrEqual'    => :op_bitor_equal,
        'OpModEqual'      => :op_mod_equal,
        'AssignExpr'      => :assign,
        'BracketAccess'   => :bracket_access,
        'DotAccessor'     => :dot_accessor,
        'Label'           => :label,
      }.each do |node,ident|
        define_method(:"visit_#{node}") do |o|
          [ident, o.left.accept(self), o.right.accept(self)]
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
