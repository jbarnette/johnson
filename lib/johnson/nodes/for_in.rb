module Johnson
  module Nodes
    class ForIn < Node
      alias :body :value
      attr_accessor :in_cond
      def initialize(line, column, in_cond, body)
        super(line, column, body)
        @in_cond = in_cond
      end
    end
  end
end
