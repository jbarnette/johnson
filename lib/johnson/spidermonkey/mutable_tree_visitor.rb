module Johnson
  module SpiderMonkey
    class MutableTreeVisitor
      include Johnson::Nodes

      %w{
        SourceElements
        VarStatement
        Comma
        ObjectLiteral
        ArrayLiteral
        New
        FunctionCall
      }.each do |list_op|
        define_method(:"visit_#{list_op}") do |ro_node|
          Nodes.const_get(list_op).new( ro_node.line,
                                        ro_node.index,
                                        ro_node.children.map { |c|
                                          c.accept(self)
                                        })
        end
      end

      def visit_For(ro_node)
        For.new(  ro_node.line,
                  ro_node.index,
                  ro_node.pn_left.pn_kid1 ? ro_node.pn_left.pn_kid1.accept(self) : nil,
                  ro_node.pn_left.pn_kid2 ? ro_node.pn_left.pn_kid2.accept(self) : nil,
                  ro_node.pn_left.pn_kid3 ? ro_node.pn_left.pn_kid3.accept(self) : nil,
                  ro_node.pn_right.accept(self)
               )
      end

      def visit_Name(ro_node)
        Name.new(ro_node.line, ro_node.index, ro_node.name)
      end

      def visit_Label(ro_node)
        Label.new(  ro_node.line,
                    ro_node.index,
                    Name.new(ro_node.line, ro_node.index, ro_node.name),
                    ro_node.pn_expr.accept(self)
                 )
      end

      def visit_AssignExpr(ro_node)
        AssignExpr.new( ro_node.line,
                        ro_node.index,
                        Name.new(ro_node.line, ro_node.index, ro_node.name),
                        ro_node.pn_expr.accept(self)
                      )
      end

      def visit_DotAccessor(ro_node)
        DotAccessor.new(  ro_node.line,
                          ro_node.index,
                          Name.new(ro_node.line, ro_node.index, ro_node.name),
                          ro_node.pn_expr.accept(self)
                       )
      end

      def visit_Number(ro_node)
        Number.new(ro_node.line, ro_node.index, ro_node.pn_dval)
      end

      def visit_Null(ro_node)
        Null.new(ro_node.line, ro_node.index, nil)
      end

      def visit_True(ro_node)
        True.new(ro_node.line, ro_node.index, true)
      end

      def visit_False(ro_node)
        False.new(ro_node.line, ro_node.index, false)
      end

      def visit_This(ro_node)
        This.new(ro_node.line, ro_node.index, 'this')
      end

      %w{
        Ternary
        If
      }.each do |node|
        define_method(:"visit_#{node}") do |ro_node|
          Nodes.const_get(node).new(
            ro_node.line,
            ro_node.index,
            ro_node.pn_kid1 ? ro_node.pn_kid1.accept(self) : nil,
            ro_node.pn_kid2 ? ro_node.pn_kid2.accept(self) : nil,
            ro_node.pn_kid3 ? ro_node.pn_kid3.accept(self) : nil
          )
        end
      end

      %w{
        BitwiseNot
        Delete
        Not
        Parenthesis
        PostfixDecrement
        PostfixIncrement
        PrefixDecrement
        PrefixIncrement
        Throw
        Typeof
        UnaryNegative
        UnaryPositive
        Void
      }.each do |node|
        define_method(:"visit_#{node}") do |ro_node|
          Nodes.const_get(node).new(ro_node.line,
                                    ro_node.index,
                                    ro_node.pn_kid.accept(self))
        end
      end

      def visit_String(ro_node)
        Nodes::String.new(  ro_node.line,
                            ro_node.index,
                            ro_node.name )
      end

      def visit_Regexp(ro_node)
        Regexp.new( ro_node.line,
                    ro_node.index,
                    ro_node.regexp )
      end

      def visit_Function(ro_node)
        Function.new( ro_node.line,
                      ro_node.index,
                      ro_node.function_name,
                      ro_node.function_args,
                      ro_node.function_body.accept(self) )
      end

      %w{
        And
        BracketAccess
        DoWhile
        While
        Equal
        In
        InstanceOf
        GetterProperty
        ForIn
        GreaterThan
        LessThan
        GreaterThanOrEqual
        LessThanOrEqual
        NotEqual
        OpAdd
        OpAddEqual
        OpBitAnd
        OpBitAndEqual
        OpBitOr
        OpBitOrEqual
        OpBitXor
        OpBitXorEqual
        OpDivide
        OpDivideEqual
        OpEqual
        OpLShift
        OpLShiftEqual
        OpMod
        OpModEqual
        OpMultiply
        OpMultiplyEqual
        OpRShift
        OpRShiftEqual
        OpSubtract
        OpSubtractEqual
        OpURShift
        OpURShiftEqual
        Or
        Property
        SetterProperty
        StrictEqual
      }.each do |bin_op|
        define_method(:"visit_#{bin_op}") do |ro_node|
          self.class.const_get(bin_op).new(
                        ro_node.line,
                        ro_node.index,
                        ro_node.pn_left.accept(self),
                        ro_node.pn_right.accept(self)
                     )
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
