module Johnson
  module Nodes
    BINARY_NODES = %w{
      And
      AssignExpr
      BracketAccess
      DotAccessor
      Equal
      GetterProperty
      Label
      NotEqual
      OpAdd
      OpAddEqual
      OpBitAnd
      OpBitAndEqual
      OpBitOr
      OpBitOrEqual
      OpBitXor
      OpBitXorEqual
      OpDivide
      OpDivideEqual
      OpEqual
      OpLShift
      OpLShiftEqual
      OpMod
      OpModEqual
      OpMultiply
      OpMultiplyEqual
      OpRShift
      OpRShiftEqual
      OpSubtract
      OpSubtractEqual
      OpURShift
      OpURShiftEqual
      Or
      Property
      SetterProperty
      StrictEqual
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
