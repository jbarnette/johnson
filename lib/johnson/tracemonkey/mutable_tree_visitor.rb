module Johnson
  module TraceMonkey
    class MutableTreeVisitor
      include Johnson::Nodes

      def visit_For(ro_node)
        For.new(  ro_node.line,
                  ro_node.index,
                  ro_node.pn_left.pn_kid1 && ro_node.pn_left.pn_kid1.accept(self),
                  ro_node.pn_left.pn_kid2 && ro_node.pn_left.pn_kid2.accept(self),
                  ro_node.pn_left.pn_kid3 && ro_node.pn_left.pn_kid3.accept(self),
                  ro_node.pn_right.accept(self)
               )
      end

      def visit_Name(ro_node)
        Name.new(ro_node.line, ro_node.index, ro_node.name)
      end

      def visit_Number(ro_node)
        Number.new(ro_node.line, ro_node.index, ro_node.pn_dval)
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

      def visit_LexicalScope(ro_node)
        LexicalScope.new(
          ro_node.line,
          ro_node.index,
          Name.new(ro_node.line, ro_node.index, "unnamed"), # lexical scope nodes don't hold a name
          ro_node.pn_expr.accept(self))
      end

      %w{ Label AssignExpr DotAccessor }.each do |type|
        define_method(:"visit_#{type}") do |ro_node|
          Nodes.const_get(type).new(
            ro_node.line,
            ro_node.index,
            Name.new(ro_node.line, ro_node.index, ro_node.name),
            ro_node.pn_expr.accept(self)
          )
        end
      end

      %w{
        SourceElements
        VarStatement
        LetStatement
        Comma
        ObjectLiteral
        ArrayLiteral
        New
        FunctionCall
        Import
        Export
      }.each do |list_op|
        define_method(:"visit_#{list_op}") do |ro_node|
          Nodes.const_get(list_op).new( ro_node.line,
                                        ro_node.index,
                                        ro_node.children.map { |c|
                                          c.accept(self)
                                        }.compact)
        end
      end

      {
        'Null'      => nil,
        'True'      => true,
        'False'     => false,
        'This'      => 'this',
        'Continue'  => 'continue',
        'Break'     => 'break',
      }.each do |type,val|
        define_method(:"visit_#{type}") do |ro_node|
          Nodes.const_get(type).new(
                                    ro_node.line,
                                    ro_node.index,
                                    val
                                   )
        end
      end

      def visit_Try(ro_node)
        Try.new(
          ro_node.line,
          ro_node.index,
          ro_node.pn_kid1 && ro_node.pn_kid1.accept(self),
          if ro_node.pn_kid2
            case ro_node.pn_kid2.pn_type
            when :tok_reserved
              ro_node.pn_kid2.children.map { |x| x.pn_expr.accept(self) }
            else
              raise "HALP some other catch #{ro_node.line}, #{ro_node.index}"
            end
          else
            nil
          end,
          ro_node.pn_kid3 && ro_node.pn_kid3.accept(self)
        )
      end

      %w{
        Ternary
        If
        Catch
      }.each do |node|
        define_method(:"visit_#{node}") do |ro_node|
          Nodes.const_get(node).new(
            ro_node.line,
            ro_node.index,
            ro_node.pn_kid1 && ro_node.pn_kid1.accept(self),
            ro_node.pn_kid2 && ro_node.pn_kid2.accept(self),
            ro_node.pn_kid3 && ro_node.pn_kid3.accept(self)
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
        Return
        Throw
        Typeof
        UnaryNegative
        UnaryPositive
        Void
      }.each do |node|
        define_method(:"visit_#{node}") do |ro_node|
          Nodes.const_get(node).new(ro_node.line,
                                    ro_node.index,
                                    ro_node.pn_kid && ro_node.pn_kid.accept(self))
        end
      end

      %w{
        And
        BracketAccess
        DoWhile
        Case
        Default
        While
        With
        Equal
        Switch
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
        StrictNotEqual
      }.each do |bin_op|
        define_method(:"visit_#{bin_op}") do |ro_node|
          if ro_node.children.length > 1
            kids = ro_node.children.reverse
            tree = self.class.const_get(bin_op).new(
                          ro_node.line,
                          ro_node.index,
                          kids[1].accept(self),
                          kids[0].accept(self)
            )
            2.times { kids.shift }
            kids.each do |kid|
              tree = self.class.const_get(bin_op).new(
                            ro_node.line,
                            ro_node.index,
                            kid.accept(self),
                            tree
              )
            end
            tree
          else
            self.class.const_get(bin_op).new(
                          ro_node.line,
                          ro_node.index,
                          ro_node.pn_left && ro_node.pn_left.accept(self),
                          ro_node.pn_right && ro_node.pn_right.accept(self)
                       )
          end
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
