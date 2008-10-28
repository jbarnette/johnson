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
              semi = case x
                     when Nodes::Function, Nodes::While, Nodes::If, Nodes::Try, Nodes::Switch, Nodes::Case, Nodes::Default, Nodes::For, Nodes::ForIn
                       code =~ /\}\Z/ ? '' : ';'
                     else
                       ';'
                     end
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

      def visit_LetStatement(o)
        "let #{o.value.map { |x| x.accept(self) }.join(', ')}"
      end

      def visit_ArrayLiteral(o)
        "[#{o.value.map { |x| x.accept(self) }.join(', ')}]"
      end

      def visit_New(o)
        rest = o.value.slice(1..-1)
        "new #{o.value.first.accept(self)}"\
          "(#{rest && rest.map { |x| x.accept(self) }.join(', ')})"
      end

      def visit_FunctionCall(o)
        rest = o.value.slice(1..-1)
        stmt =
          if o.value.first.is_a?(Nodes::Function)
            "(#{o.value.first.accept(self)})"
          else
            "#{o.value.first.accept(self)}"
          end
        "#{stmt}(#{rest && rest.map { |x| x.accept(self) }.join(', ')})"
      end

      def visit_Comma(o)
        "#{o.value.map { |x| x.accept(self) }.join(', ') }"
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
        h = {
          "\b"  => '\b',
          "\t"  => '\t',
          "\n"  => '\n',
          "\f"  => '\f',
          "\r"  => '\r',
        }
        "\"#{o.value.gsub(/[\\]/, '\\\\\\').gsub(/"/, '\"').gsub(/[\b\t\n\f\r]/) { |m| h[m] }}\""
      end

      {
        'Break'     => 'break',
        'Continue'  => 'continue',
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

      def visit_LexicalScope(o)
        "#{o.right.accept(self)}"
      end
      
      def visit_DoWhile(o)
        semi = o.left.is_a?(Nodes::SourceElements) ? '' : ';'
        "do #{o.left.accept(self)}#{semi} while(#{o.right.accept(self)})"
      end

      def visit_Try(o)
        stmt = "try #{o.cond.accept(self)}"
        o.b_then.each do |node|
          stmt << " #{node.accept(self)}"
        end if o.b_then
        stmt << "#{o.b_else && ' finally '}" \
          "#{o.b_else && o.b_else.accept(self)}" if o.b_else
        stmt
      end

      def visit_Catch(o)
        "catch(#{o.cond.accept(self)}) #{o.b_else.accept(self)}"
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

      def visit_Throw(o)
        "throw #{o.value.accept(self)}"
      end

      def visit_Void(o)
        "void #{o.value.accept(self)}"
      end

      def visit_Return(o)
        "return#{o.value && ' '}#{o.value && o.value.accept(self)}"
      end

      def visit_Typeof(o)
        "typeof #{o.value.accept(self)}"
      end

      {
        'UnaryPositive' => '+',
        'UnaryNegative' => '-',
        'BitwiseNot'    => '~',
        'Not'           => '!',
      }.each do |type,op|
        define_method(:"visit_#{type}") do |o|
          "#{op}#{o.value.accept(self)}"
        end
      end

      def visit_Parenthesis(o)
        "(#{o.value.accept(self)})"
      end

      def visit_While(o)
        "while(#{o.left.accept(self)}) #{o.right.accept(self)}"
      end

      def visit_With(o)
        "with(#{o.left.accept(self)}) #{o.right.accept(self)}"
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
        stmt =
          if o.right.is_a?(Nodes::Function)
            "(#{o.right.accept(self)})"
          else
            "#{o.right.accept(self)}"
          end

        rhs = o.left.accept(self)
        if rhs =~ /\A\w+$/
          stmt << ".#{rhs}"
        else
          stmt << "['#{rhs}']"
        end
        stmt
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
        'PrefixIncrement'  => '++',
        'PrefixDecrement'  => '--',
      }.each do |type,op|
        define_method(:"visit_#{type}") do |o|
          "#{op}#{o.value.accept(self)}"
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
