require 'stringio'

module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class ImmutableNode
      def accept(visitor)
        case pn_arity
        when :pn_list
          handle_list(visitor)
        when :pn_name
          if pn_expr
            m = {
              :tok_colon  => :visit_Label,
              :tok_name   => :visit_AssignExpr,
              :tok_dot    => :visit_DotAccessor,
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
        m = {
          :tok_lc     => :visit_SourceElements,
          :tok_var    => :visit_VarStatement,
          :tok_comma  => :visit_Comma,
          :tok_rc     => :visit_ObjectLiteral,
          :tok_rb     => :visit_ArrayLiteral,
          :tok_new    => :visit_New,
          :tok_lp     => :visit_FunctionCall,
        }[pn_type]
        raise "Unknown type: #{pn_type}" unless m
        visitor.send(m, self)
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
        when :tok_lb
          visitor.visit_BracketAccess(self)
        when :tok_colon
          m = {
            :jsop_getter  => :visit_GetterProperty,
            :jsop_setter  => :visit_SetterProperty,
            :jsop_nop     => :visit_Property
          }[pn_op]
          raise "Unknown assign op #{pn_op}" unless m
          visitor.send(m, self)
        else
          raise "Unknown binary type: #{pn_type}"
        end
      end
    end
  end
end
