module Johnson
  module Nodes
    TERNARY_NODES = %w{
      Ternary
      If
      Try
      Catch
    }
    class TernaryNode < Node
      alias :b_else :value
      attr_accessor :cond, :b_then
      def initialize(line, column, cond, b_then, b_else)
        super(line, column, b_else)
        @cond   = cond
        @b_then = b_then
      end
    end
    TERNARY_NODES.each { |bn| const_set(bn.to_sym, Class.new(TernaryNode)) }
  end
end
