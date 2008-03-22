module Johnson
  module Nodes
    class Ternary < Node
      alias :b_else :value
      attr_accessor :cond, :b_then
      def initialize(line, column, cond, b_then, b_else)
        super(line, column, b_else)
        @cond   = cond
        @b_then = b_then
      end
    end
  end
end
