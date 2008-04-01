module Johnson
  module Visitors
    class EcmaVisitor
      def initialize
        @depth = 0
      end

      def visit_SourceElements(o)
        (@depth == 0 ? '' : "{\n") +
          indent {
            o.value.map { |x|
              code = x.accept(self)
              semi = code =~ /}\Z/ ? '' : ';'
              "#{indent}#{code}#{semi}"
            }.join("\n")
          } +
          (@depth == 0 ? '' : "\n}")
      end

      def visit_For(o)
        "for(#{o.init ? o.init.accept(self) : ' '};" \
          " #{o.cond && o.cond.accept(self)};" \
          " #{o.update && o.update.accept(self)}) #{o.body.accept(self)}"
      end

      def visit_ForIn(o)
        "for(#{o.in_cond.accept(self)}) #{o.body.accept(self)}"
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

      def visit_DotAccessor(o)
        "#{o.right.accept(self)}.#{o.left.accept(self)}"
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