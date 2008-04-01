module Johnson
  module Visitors
    class EcmaVisitor
      def initialize
        @depth = 0
      end

      def visit_SourceElements(o)
        newline = o.value.length > 0 ? "\n" : ' '
        (@depth == 0 ? '' : "{#{newline}") +
          indent {
            o.value.map { |x|
              code = x.accept(self)
              semi = code =~ /}\Z/ ? '' : ';'
              "#{indent}#{code}#{semi}"
            }.join("\n")
          } +
          (@depth == 0 ? '' : "#{newline}}")
      end

      def visit_For(o)
        "for(#{o.init ? o.init.accept(self) : ' '};" \
          " #{o.cond && o.cond.accept(self)};" \
          " #{o.update && o.update.accept(self)}) #{o.body.accept(self)}"
      end

      def visit_ForIn(o)
        "for(#{o.in_cond.accept(self)}) #{o.body.accept(self)}"
      end

      def visit_Ternary(o)
        "#{o.cond.accept(self)} ? #{o.b_then.accept(self)} : " \
          "#{o.b_else.accept(self)}"
      end

      def visit_VarStatement(o)
        "var #{o.value.map { |x| x.accept(self) }.join(', ')}"
      end

      def visit_ArrayLiteral(o)
        "[#{o.value.map { |x| x.accept(self) }.join(', ')}]"
      end

      %w{ Name Number Regexp }.each do |type|
        define_method(:"visit_#{type}") do |o|
          o.value
        end
      end

      def visit_If(o)
        semi = ''
        semi = ';' if o.b_else && !o.b_then.is_a?(Nodes::SourceElements)

        stmt = "if(#{o.cond.accept(self)}) #{o.b_then.accept(self)}#{semi}"
        stmt += " else #{o.b_else.accept(self)}" if o.b_else
        stmt
      end

      def visit_Function(o)
        "function#{o.name && ' '}#{o.name}(#{o.arguments.join(', ')}) #{o.body.accept(self)}"
      end

      def visit_String(o)
        "\"#{o.value}\""
      end

      {
        'Break'     => 'break;',
        'Continue'  => 'continue;',
        'Null'      => 'null',
        'True'      => 'true',
        'False'     => 'false',
        'This'      => 'this',
      }.each do |type,sym|
        define_method(:"visit_#{type}") do |o|
          sym
        end
      end

      def visit_BracketAccess(o)
        "#{o.left.accept(self)}[#{o.right.accept(self)}]"
      end
      
      def visit_DoWhile(o)
        semi = o.left.is_a?(Nodes::SourceElements) ? '' : ';'
        "do #{o.left.accept(self)}#{semi} while(#{o.right.accept(self)})"
      end

      def visit_Delete(o)
        "delete #{o.value.accept(self)}"
      end

      def visit_Export(o)
        "export #{o.value.map { |x| x.accept(self) }.join(', ')}"
      end

      def visit_Import(o)
        "import #{o.value.map { |x| x.accept(self) }.join(', ')}"
      end

      def visit_Return(o)
        "return#{o.value && ' '}#{o.value && o.value.accept(self)}"
      end

      def visit_Switch(o)
        "switch(#{o.left.accept(self)}) #{o.right.accept(self)}"
      end

      def visit_Case(o)
        "case #{o.left.accept(self)}: #{o.right.accept(self)}"
      end

      def visit_Default(o)
        "default: #{o.right.accept(self)}"
      end

      def visit_Label(o)
        "#{o.left.accept(self)}: #{o.right.accept(self)}"
      end
      alias :visit_Property :visit_Label

      def visit_DotAccessor(o)
        "#{o.right.accept(self)}.#{o.left.accept(self)}"
      end

      def visit_GetterProperty(o)
        "get #{o.left.accept(self)}#{o.right.accept(self).gsub(/function/, '')}"
      end

      def visit_SetterProperty(o)
        "set #{o.left.accept(self)}#{o.right.accept(self).gsub(/function/, '')}"
      end

      def visit_ObjectLiteral(o)
        indent {
          "{ #{o.value.map { |x| x.accept(self) }.join(",\n#{indent}")} }"
        }
      end

      {
        'PostfixIncrement'  => '++',
        'PostfixDecrement'  => '--',
      }.each do |type,op|
        define_method(:"visit_#{type}") do |o|
          "#{o.value.accept(self)}#{op}"
        end
      end

      {
        'OpEqual'             => '=',
        'StrictNotEqual'      => '!==',
        'StrictEqual'         => '===',
        'Or'                  => '||',
        'OpURShift'           => '>>>',
        'OpURShiftEqual'      => '>>>=',
        'OpSubtract'          => '-',
        'OpSubtractEqual'     => '-=',
        'OpRShift'            => '>>',
        'OpRShiftEqual'       => '>>=',
        'OpMultiply'          => '*',
        'OpMultiplyEqual'     => '*=',
        'OpMod'               => '%',
        'OpModEqual'          => '%=',
        'OpLShift'            => '<<',
        'OpLShiftEqual'       => '<<=',
        'OpDivide'            => '/',
        'OpDivideEqual'       => '/=',
        'OpBitXor'            => '^',
        'OpBitXorEqual'       => '^=',
        'OpBitOr'             => '|',
        'OpBitOrEqual'        => '|=',
        'OpBitAnd'            => '&',
        'OpBitAndEqual'       => '&=',
        'OpAdd'               => '+',
        'OpAddEqual'          => '+=',
        'NotEqual'            => '!=',
        'LessThan'            => '<',
        'LessThanOrEqual'     => '<=',
        'GreaterThan'         => '>',
        'GreaterThanOrEqual'  => '>=',
        'And'                 => '&&',
        'InstanceOf'          => 'instanceof',
        'In'                  => 'in',
        'Equal'               => '==',
        'AssignExpr'          => '=',
      }.each do |type,op|
        define_method(:"visit_#{type}") do |o|
          "#{o.left && o.left.accept(self)}" \
            " #{op} " \
            "#{o.right && o.right.accept(self)}"
        end
      end

      def accept(target)
        target.accept(self)
      end

      private
      def indent
        if block_given?
          @depth += 1
          x = yield
          @depth -= 1
          x
        else
          ' ' * (@depth - 1) * 2
        end
      end
    end
  end
end
