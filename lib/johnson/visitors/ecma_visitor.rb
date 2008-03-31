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

      %w{ Name Number Regexp String }.each do |type|
        define_method(:"visit_#{type}") do |o|
          o.value
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
        'Equal'               => '==',
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
