module Johnson
  module Nodes
    LIST_NODES = %w{
      SourceElements
      VarStatement
      LetStatement
      Comma
      ObjectLiteral
      ArrayLiteral
      New
      FunctionCall
      Import
      Export
    }
    # This is an abstract node used for nodes of list type
    # see SourceElements
    class List < Node
      def initialize(line, column, value = [])
        super
      end

      def <<(obj)
        self.value << obj
      end
    end
    LIST_NODES.each { |ln| const_set(ln.to_sym, Class.new(List)) }
  end
end
