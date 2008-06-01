module Johnson
  module Nodes
    SINGLE_NODES = %w{
      BitwiseNot
      Break
      Continue
      Delete
      False
      Name
      Not
      Null
      Number
      Parenthesis
      PostfixIncrement
      PrefixIncrement
      PostfixDecrement
      PrefixDecrement
      Regexp
      Return
      String
      This
      Throw
      True
      Typeof
      UnaryNegative
      UnaryPositive
      Void
    }
    class Node
      include Johnson::Visitable
      include Johnson::Visitors

      attr_accessor :value
      attr_reader :line, :column
      def initialize(line, column, value)
        @line = line
        @column = column
        @value = value
      end

      def to_s
        to_sexp.inspect
      end

      alias_method :inspect, :to_s

      def to_sexp
        SexpVisitor.new.accept(self)
      end

      def to_ecma
        EcmaVisitor.new.accept(self)
      end

      alias_method :to_js, :to_ecma

      def to_dot
        DotVisitor.new { |d| d.accept(self) }
      end

      def each(&block)
        EnumeratingVisitor.new(block).accept(self)
        self
      end
    end
    SINGLE_NODES.each { |se| const_set(se.to_sym, Class.new(Node)) }
  end
end
