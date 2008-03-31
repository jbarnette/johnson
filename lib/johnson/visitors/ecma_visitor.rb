module Johnson
  module Visitors
    class EcmaVisitor
      def initialize
        @depth = 0
      end

      def visit_SourceElements(o)
        (@depth == 0 ? '' : '{') +
          o.value.map { |x| "#{indent}#{x.accept(self)}" }.join("\n") +
          (@depth == 0 ? '' : '}')
      end

      def visit_VarStatement(o)
        "var #{o.value.map { |x| x.accept(self) }.join(', ')};"
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
      def indent; ' ' * @depth * 2; end
    end
  end
end
