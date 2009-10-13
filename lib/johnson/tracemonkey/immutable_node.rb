module Johnson #:nodoc:
  module TraceMonkey #:nodoc:
    class ImmutableNode
      def accept(visitor)
        case pn_arity
        when :pn_list
          handle_list(visitor)
        when :pn_name
          if !pn_used && pn_expr
            m = {
              :tok_colon  => :visit_Label,
              :tok_name   => :visit_AssignExpr,
              :tok_dot    => :visit_DotAccessor,
              :tok_lexicalscope => :visit_LexicalScope
            }[pn_type]
            raise "Unknown type #{pn_type}" unless m
            visitor.send(m, self)
          else
            visitor.visit_Name(self)
          end
        when :pn_binary
          handle_binary(visitor)
        when :pn_unary
          handle_unary(visitor)
        when :pn_nullary
          handle_nullary(visitor)
        when :pn_func
          visitor.visit_Function(self)
        when :pn_ternary
          m = {
            :tok_hook   => :visit_Ternary,
            :tok_if     => :visit_If,
            :tok_try    => :visit_Try,
            :tok_catch  => :visit_Catch,
          }[pn_type]
          raise "Unknown ternary #{pn_type}" unless m
          visitor.send(m, self)
        else
          raise "unkown arity: #{pn_arity}"
        end
      end

      def to_mutable_tree
        MutableTreeVisitor.new.accept(self)
      end

      def to_sexp
        to_mutable_tree.to_sexp
      end

      private
      def handle_unary(visitor)
        case pn_type
        when :tok_throw
          visitor.visit_Throw(self)
        when :tok_delete
          visitor.visit_Delete(self)
        when :tok_return
          visitor.visit_Return(self)
        when :tok_unaryop
          m = {
            :jsop_void    => :visit_Void,
            :jsop_typeof  => :visit_Typeof,
            :jsop_pos     => :visit_UnaryPositive,
            :jsop_neg     => :visit_UnaryNegative,
            :jsop_bitnot  => :visit_BitwiseNot,
            :jsop_not     => :visit_Not,
          }[pn_op]
          raise "Unknown tok_unaryop type: #{pn_op}" unless m
          visitor.send(m, self)
        when :tok_rp
          visitor.visit_Parenthesis(self)
        when :tok_inc
          m = {
            :jsop_nameinc => :visit_PostfixIncrement,
            :jsop_propinc => :visit_PostfixIncrement,
            :jsop_eleminc => :visit_PostfixIncrement,
            :jsop_incname => :visit_PrefixIncrement,
            :jsop_incprop => :visit_PrefixIncrement,
            :jsop_incelem => :visit_PrefixIncrement,
          }[pn_op]
          raise "Unknown increment type: #{pn_op}" unless m
          visitor.send(m, self)
        when :tok_dec
          m = {
            :jsop_namedec => :visit_PostfixDecrement,
            :jsop_propdec => :visit_PostfixDecrement,
            :jsop_elemdec => :visit_PostfixDecrement,
            :jsop_decname => :visit_PrefixDecrement,
            :jsop_decprop => :visit_PrefixDecrement,
            :jsop_decelem => :visit_PrefixDecrement,
          }[pn_op]
          raise "Unknown decrement type: #{pn_op}" unless m
          visitor.send(m, self)
        when :tok_semi
          pn_kid.accept(visitor) if pn_kid
        else
          raise "unknown unary: #{pn_type}"
        end
      end

      def handle_list(visitor)
        case pn_type
        when :tok_shop
          handle_shiftop(visitor)
        when :tok_divop
          handle_divop(visitor)
        when :tok_eqop
          handle_eqop(visitor)
        when :tok_relop
          handle_relop(visitor)
        else
          m = {
            :tok_lc         => :visit_SourceElements,
            :tok_var        => :visit_VarStatement,
            :tok_let        => :visit_LetStatement,
            :tok_comma      => :visit_Comma,
            :tok_rc         => :visit_ObjectLiteral,
            :tok_rb         => :visit_ArrayLiteral,
            :tok_new        => :visit_New,
            :tok_lp         => :visit_FunctionCall,
            :tok_import     => :visit_Import,
            :tok_export     => :visit_Export,
            :tok_plus       => :visit_OpAdd,
            :tok_or         => :visit_Or,
            :tok_minus      => :visit_OpSubtract,
            :tok_and        => :visit_And,
            :tok_bitand     => :visit_OpBitAnd,
            :tok_bitor      => :visit_OpBitOr,
            :tok_bitxor     => :visit_OpBitXor,
            :tok_star       => :visit_OpMultiply,
            :tok_instanceof => :visit_InstanceOf,
          }[pn_type]
          raise "Unknown type: #{pn_type} at (#{line}, #{index})" unless m
          visitor.send(m, self)
        end
      end

      OP_TO_METHOD = {
        :jsop_null  => :visit_Null,
        :jsop_true  => :visit_True,
        :jsop_false => :visit_False,
        :jsop_this  => :visit_This,
      }
      def handle_nullary(visitor)
        case pn_type
        when :tok_number
          visitor.visit_Number(self)
        when :tok_string
          visitor.visit_String(self)
        when :tok_regexp
          visitor.visit_Regexp(self)
        when :tok_name
          visitor.visit_Name(self)
        when :tok_comma
          visitor.visit_Null(self)
        when :tok_continue
          visitor.visit_Continue(self)
        when :tok_break
          visitor.visit_Break(self)
        when :tok_primary
          sym = OP_TO_METHOD[pn_op]
          raise "Unknown op #{pn_op}" unless sym
          visitor.send(sym, self)
        else
          raise "Unknown nullary type: #{pn_type}"
        end
      end

      def handle_binary(visitor)
        case pn_type
        when :tok_assign
          m = {
            :jsop_add     => :visit_OpAddEqual,
            :jsop_sub     => :visit_OpSubtractEqual,
            :jsop_nop     => :visit_OpEqual,
            :jsop_mul     => :visit_OpMultiplyEqual,
            :jsop_div     => :visit_OpDivideEqual,
            :jsop_lsh     => :visit_OpLShiftEqual,
            :jsop_rsh     => :visit_OpRShiftEqual,
            :jsop_ursh    => :visit_OpURShiftEqual,
            :jsop_bitand  => :visit_OpBitAndEqual,
            :jsop_bitxor  => :visit_OpBitXorEqual,
            :jsop_bitor   => :visit_OpBitOrEqual,
            :jsop_mod     => :visit_OpModEqual,
          }[pn_op]
          raise "Unknown assign op #{pn_op}" unless m
          visitor.send(m, self)
        when :tok_divop
          handle_divop(visitor)
        when :tok_shop
          handle_shiftop(visitor)
        when :tok_eqop
          handle_eqop(visitor)
        when :tok_colon
          m = {
            :jsop_getter  => :visit_GetterProperty,
            :jsop_setter  => :visit_SetterProperty,
            :jsop_nop     => :visit_Property
          }[pn_op]
          raise "Unknown assign op #{pn_op}" unless m
          visitor.send(m, self)
        when :tok_relop
          handle_relop(visitor)
        when :tok_for
          if pn_left.pn_type == :tok_in
            visitor.visit_ForIn(self)
          else
            visitor.visit_For(self)
          end
        else
          m = {
            :tok_while      => :visit_While,
            :tok_with       => :visit_With,
            :tok_default    => :visit_Default,
            :tok_case       => :visit_Case,
            :tok_switch     => :visit_Switch,
            :tok_do         => :visit_DoWhile,
            :tok_instanceof => :visit_InstanceOf,
            :tok_in         => :visit_In,
            :tok_and        => :visit_And,
            :tok_or         => :visit_Or,
            :tok_star       => :visit_OpMultiply,
            :tok_lb         => :visit_BracketAccess,
            :tok_minus      => :visit_OpSubtract,
            :tok_plus       => :visit_OpAdd,
            :tok_bitor      => :visit_OpBitOr,
            :tok_bitxor     => :visit_OpBitXor,
            :tok_bitand     => :visit_OpBitAnd,
          }[pn_type]
          raise "Unknown binary type: #{pn_type}" unless m
          visitor.send(m, self)
        end
      end

      def handle_shiftop(visitor)
        m = {
          :jsop_ursh  => :visit_OpURShift,
          :jsop_rsh   => :visit_OpRShift,
          :jsop_lsh   => :visit_OpLShift,
        }[pn_op]
        raise "Unknown shift op #{pn_op} at (#{line}, #{index})" unless m
        visitor.send(m, self)
      end

      def handle_divop(visitor)
        m = {
          :jsop_div => :visit_OpDivide,
          :jsop_mod => :visit_OpMod,
        }[pn_op]
        raise "Unknown assign op #{pn_op} at (#{line}, #{index})" unless m
        visitor.send(m, self)
      end

      def handle_eqop(visitor)
        m = {
          :jsop_strictne  => :visit_StrictNotEqual,
          :jsop_stricteq  => :visit_StrictEqual,
          :jsop_ne        => :visit_NotEqual,
          :jsop_eq        => :visit_Equal,
        }[pn_op]
        raise "Unknown equal op #{pn_op} at (#{line}, #{index})" unless m
        visitor.send(m, self)
      end

      def handle_relop(visitor)
        m = {
          :jsop_ge  => :visit_GreaterThanOrEqual,
          :jsop_le  => :visit_LessThanOrEqual,
          :jsop_gt  => :visit_GreaterThan,
          :jsop_lt  => :visit_LessThan,
        }[pn_op]
        raise "Unknown relop #{pn_op} at (#{line}, #{index})" unless m
        visitor.send(m, self)
      end

      def raise_parse_error(message, file_name, line_number)
        raise Johnson::Parser::SyntaxError.new(message, file_name, line_number)
      end
    end
  end
end
