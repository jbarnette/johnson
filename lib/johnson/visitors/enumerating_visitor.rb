module Johnson
  module Visitors
    class EnumeratingVisitor < Visitor
      attr_accessor :block
      def initialize(block)
        @block = block
      end

      superclass.instance_methods.each do |method|
        next unless method.to_s =~ /^visit_/
        eval("def #{method}(o); block.call(o); super; end")
      end
    end
  end
end
