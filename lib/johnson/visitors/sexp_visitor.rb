module Johnson
  module Visitors
    class SexpVisitor
      def visit_SourceElements(o)
        o.value.map { |x| x.accept(self) }
      end

      {
        'VarStatement'  => :var,
        'LetStatement'  => :let,
        'Comma'         => :comma,
        'ObjectLiteral' => :object,
        'ArrayLiteral'  => :array,
        'New'           => :new,
        'FunctionCall'  => :function_call,
        'Import'        => :import,
        'Export'        => :export,
      }.each do |type,sym|
        define_method(:"visit_#{type}") do |o|
          [sym, o.value.map { |x| x.accept(self) }]
        end
      end

      { 
        'Name'    => :name,
        'Number'  => :lit,
        'Regexp'  => :lit,
        'String'  => :str 
      }.each do |type,sym|
        define_method(:"visit_#{type}") do |o|
          [sym, o.value]
        end
      end

      {
        'Break'     => :break,
        'Continue'  => :continue,
        'Null'      => :nil,
        'True'      => :true,
        'False'     => :false,
        'This'      => :this,
      }.each do |type,sym|
        define_method(:"visit_#{type}") do |o|
          [sym]
        end
      end

      def visit_For(o)
        [ :for,
          o.init && o.init.accept(self),
          o.cond && o.cond.accept(self),
          o.update && o.update.accept(self),
          o.body.accept(self)
        ]
      end

      def visit_ForIn(o)
        [ :for_in,
          o.in_cond.accept(self),
          o.body.accept(self)
        ]
      end

      def visit_Try(o)
        [ :try,
          o.cond.accept(self),
          o.b_then ? o.b_then.map { |x| x.accept(self) } : nil,
          o.b_else ? o.b_else.accept(self) : nil
        ]
      end

      {
        'Ternary' => :ternary,
        'If'      => :if,
        'Catch'   => :catch,
      }.each do |node,ident|
        define_method(:"visit_#{node}") do |o|
          [ ident,
            o.cond.accept(self),
            o.b_then ? o.b_then.accept(self) : nil,
            o.b_else ? o.b_else.accept(self) : nil
          ]
        end
      end
      ### UNARY NODES ###
      {
        'Throw'             => :throw,
        'Delete'            => :delete,
        'Void'              => :void,
        'Typeof'            => :typeof,
        'PrefixDecrement'   => :prefix_dec,
        'PostfixDecrement'  => :postfix_dec,
        'PrefixIncrement'   => :prefix_inc,
        'PostfixIncrement'  => :postfix_inc,
        'Parenthesis'       => :paren,
        'Return'            => :return,
        'UnaryNegative'     => :u_neg,
        'UnaryPositive'     => :u_pos,
        'BitwiseNot'        => :bitwise_not,
        'Not'               => :not,
      }.each do |node,ident|
        define_method(:"visit_#{node}") do |o|
          [ident, o.value && o.value.accept(self)]
        end
      end

      ### FUNCTION NODES ###
      def visit_Function(o)
        [:func_expr, o.name, o.arguments, o.body.accept(self)]
      end

      ### BINARY NODES ###
      {
        'In'                  => :in,
        'InstanceOf'          => :instanceof,
        'Switch'              => :switch,
        'Case'                => :case,
        'Default'             => :default,
        'With'                => :with,
        'DoWhile'             => :do_while,
        'While'               => :while,
        'Property'            => :property,
        'GreaterThanOrEqual'  => :gt_equal,
        'LessThanOrEqual'     => :lt_equal,
        'GreaterThan'         => :gt,
        'LessThan'            => :lt,
        'GetterProperty'      => :getter,
        'SetterProperty'      => :setter,
        'OpEqual'             => :op_equal,
        'OpMultiply'          => :op_multiply,
        'OpMultiplyEqual'     => :op_multiply_equal,
        'OpAddEqual'          => :op_add_equal,
        'OpSubtractEqual'     => :op_subtract_equal,
        'OpAdd'               => :op_add,
        'OpSubtract'          => :op_subtract,
        'OpDivideEqual'       => :op_divide_equal,
        'OpDivide'            => :op_divide,
        'OpLShiftEqual'       => :op_lshift_equal,
        'OpRShiftEqual'       => :op_rshift_equal,
        'OpURShiftEqual'      => :op_urshift_equal,
        'OpLShift'            => :op_lshift,
        'OpRShift'            => :op_rshift,
        'OpURShift'           => :op_urshift,
        'OpBitAndEqual'       => :op_bitand_equal,
        'OpBitAnd'            => :op_bitand,
        'OpBitXorEqual'       => :op_bitxor_equal,
        'OpBitOrEqual'        => :op_bitor_equal,
        'OpBitXor'            => :op_bitxor,
        'OpBitOr'             => :op_bitor,
        'OpModEqual'          => :op_mod_equal,
        'OpMod'               => :op_mod,
        'AssignExpr'          => :assign,
        'BracketAccess'       => :bracket_access,
        'DotAccessor'         => :dot_accessor,
        'LexicalScope'        => :lexical_scope,
        'Equal'               => :equal,
        'NotEqual'            => :not_equal,
        'Or'                  => :or,
        'And'                 => :and,
        'StrictEqual'         => :strict_equal,
        'StrictNotEqual'      => :strict_not_equal,
        'Label'               => :label,
      }.each do |node,ident|
        define_method(:"visit_#{node}") do |o|
          [ident, o.left && o.left.accept(self), o.right &&o.right.accept(self)]
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
