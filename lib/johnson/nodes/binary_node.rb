module Johnson
  module Nodes
    BINARY_NODES = %w{
      And
      AssignExpr
      BracketAccess
      DotAccessor
      Equal
      NotEqual
      StrictEqual
      Label
      OpBitAndEqual
      OpBitAnd
      OpBitXorEqual
      OpBitOrEqual
      OpBitXor
      OpBitOr
      OpDivide
      OpDivideEqual
      OpEqual
      OpModEqual
      OpMod
      OpMultiply
      OpLShiftEqual
      OpRShiftEqual
      OpURShiftEqual
      OpLShift
      OpRShift
      OpURShift
      OpMultiplyEqual
      OpAddEqual
      OpSubtractEqual
      OpAdd
      OpSubtract
      Or
      Property
      GetterProperty
      SetterProperty
    }

    class BinaryNode < Node
      alias :right :value
      attr_accessor :left
      def initialize(line, column, left, right)
        super(line, column, right)
        @left = left
      end
    end
    BINARY_NODES.each { |bn| const_set(bn.to_sym, Class.new(BinaryNode)) }
  end
end
