module Johnson
  module Nodes
    class For < Node
      alias :body :value
      attr_accessor :init, :cond, :update
      def initialize(line, column, init, cond, update, body)
        super(line, column, body)
        @init   = init
        @cond   = cond
        @update = update
      end
    end
  end
end
