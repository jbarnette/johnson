module Johnson
  module Visitors
    class DotVisitor
      attr_accessor :nodes, :links

      ESCAPE = /([<>"\\])/

      class Node < Struct.new(:node_id, :label, :fields)
        def to_s
          f = fields.map { |field|
            field.to_s.gsub(ESCAPE, '\\\\\1').gsub(/[\r\n]/, ' ')
          }.join('\n')
          f = "\\n#{f}" if f.length > 0
          "\"#{node_id}\" [ label = \"#{label}#{f}\" ];"
        end
      end
      class Link < Struct.new(:from, :to, :attributes)
        def to_s
          attrs = ''
          if attributes
            attrs = " [" + attributes.map { |attribute|
              attribute.join(' = ')
            }.join("; ") + "]"
          end
          "\"#{from}\" -> \"#{to}\"#{attrs};"
        end
      end

      def initialize
        @nodes = []
        @links = []
        @color = 'lightblue2'
        @style = 'filled'
        yield self if block_given?
      end

      def to_s
        "digraph parsetree {\n" +
          "  node [color=#{@color}, style=#{@style}];\n" +
          @nodes.map { |n| n.to_s }.join("\n") +
          @links.map { |n| n.to_s }.join("\n") +
          "\n}"
      end

      def visit_SourceElements(o)
        @nodes << Node.new(o.object_id, 'SourceElements', [])
        o.value.each { |x|
          @links << Link.new(o.object_id, x.object_id)
          x.accept(self)
        }
      end

      %w{
        VarStatement
        LetStatement
        Comma
        ObjectLiteral
        ArrayLiteral
        New
        FunctionCall
        Import
        Export
      }.each do |type|
        define_method(:"visit_#{type}") do |o|
          @nodes << Node.new(o.object_id, type, [])
          o.value.each { |x|
            @links << Link.new(o.object_id, x.object_id)
            x.accept(self)
          }
        end
      end

      %w{ Name Number Regexp String }.each do |type|
        define_method(:"visit_#{type}") do |o|
          @nodes << Node.new(o.object_id, type, [o.value])
        end
      end

      %w{ Break Continue False Null This True }.each do |type|
        define_method(:"visit_#{type}") do |o|
          @nodes << Node.new(o.object_id, type, [])
        end
      end

      def visit_Try(o)
        @nodes << Node.new(o.object_id, 'Try', [])
        @links << Link.new(o.object_id, o.cond.object_id, {'label' => 'cond' })
        o.cond.accept(self)
        if o.b_then
          o.b_then.each { |x|
            @links << Link.new(o.object_id, x.object_id, {'label' => 'b_then' })
            x.accept(self)
          }
        end
        if x = o.b_else
          @links << Link.new(o.object_id, x.object_id, {'label' => 'b_else' })
          x.accept(self)
        end
      end

      {
        'For'     => [:init, :cond, :update, :body],
        'ForIn'   => [:in_cond, :body],
        'Ternary' => [:cond, :b_then, :b_else],
        'If'      => [:cond, :b_then, :b_else],
        'Catch'   => [:cond, :b_then, :b_else],
      }.each do |type,attrs|
        define_method(:"visit_#{type}") do |o|
          @nodes << Node.new(o.object_id, type, [])
          attrs.each do |method|
            if x = o.send(method)
              @links << Link.new(o.object_id, x.object_id, {'label' => method })
              x.accept(self)
            end
          end
        end
      end

      ### UNARY NODES ###
      %w{
        BitwiseNot Delete Not Parenthesis PostfixDecrement PostfixIncrement
        PrefixDecrement PrefixIncrement Return Throw Typeof UnaryNegative
        UnaryPositive Void
      }.each do |node|
        define_method(:"visit_#{node}") do |o|
          @nodes << Node.new(o.object_id, node, [])
          if x = o.value
            @links << Link.new(o.object_id, x.object_id)
            x.accept(self)
          end
        end
      end

      ### FUNCTION NODES ###
      def visit_Function(o)
        @nodes << Node.new(o.object_id, 'Function', [o.arguments.join(', ')])
        @links << Link.new(o.object_id, o.body.object_id, { 'label' => 'body' })
        o.body.accept(self)
      end

      ### BINARY NODES ###
      %w{
        And AssignExpr BracketAccess Case Default DoWhile DotAccessor
        Equal GetterProperty GreaterThan GreaterThanOrEqual In
        InstanceOf Label LessThan LessThanOrEqual NotEqual OpAdd OpAddEqual
        OpBitAnd OpBitAndEqual OpBitOr OpBitOrEqual OpBitXor OpBitXorEqual
        OpDivide OpDivideEqual OpEqual OpLShift OpLShiftEqual OpMod
        OpModEqual OpMultiply OpMultiplyEqual OpRShift OpRShiftEqual
        OpSubtract OpSubtractEqual OpURShift OpURShiftEqual Or Property
        SetterProperty StrictEqual StrictNotEqual Switch While With
        LexicalScope
      }.each do |node|
        define_method(:"visit_#{node}") do |o|
          @nodes << Node.new(o.object_id, node, [])
          [:left, :right].each do |side|
            if x = o.send(side)
              @links << Link.new(o.object_id, x.object_id, { 'label' => side })
              x.accept(self)
            end
          end
        end
      end

      def accept(target)
        target.accept(self)
      end
    end
  end
end
