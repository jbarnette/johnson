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

      def visit_Throw(ro_node)
        Throw.new(ro_node.line, ro_node.index, ro_node.pn_kid.accept(self))
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

      def visit_Parenthesis(ro_node)
        Parenthesis.new(  ro_node.line,
                          ro_node.index,
                          ro_node.pn_kid.accept(self))
      end

      def visit_PostfixIncrement(ro_node)
        PostfixIncrement.new( ro_node.line,
                              ro_node.index,
                              ro_node.pn_kid.accept(self))
      end

      def visit_PrefixIncrement(ro_node)
        PrefixIncrement.new(  ro_node.line,
                              ro_node.index,
                              ro_node.pn_kid.accept(self))
      end

      def visit_PostfixDecrement(ro_node)
        PostfixDecrement.new( ro_node.line,
                              ro_node.index,
                              ro_node.pn_kid.accept(self))
      end

      def visit_PrefixDecrement(ro_node)
        PrefixDecrement.new(  ro_node.line,
                              ro_node.index,
                              ro_node.pn_kid.accept(self))
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
        OpEqual
        OpBitAndEqual
        OpBitXorEqual
        OpBitOrEqual
        OpPlusEqual
        OpModEqual
        OpMultiplyEqual
        OpDivideEqual
        OpLShiftEqual
        OpRShiftEqual
        OpURShiftEqual
        BracketAccess
        Property
        GetterProperty
        SetterProperty
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
