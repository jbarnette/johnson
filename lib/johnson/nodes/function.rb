module Johnson
  module Nodes
    class Function < Node
      alias :body :value
      attr_accessor :name, :arguments
      def initialize(line, column, name, arguments, body)
        super(line, column, body)
        @name       = name
        @arguments  = arguments
      end
    end
  end
end
