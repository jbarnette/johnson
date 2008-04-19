require 'stringio'
require 'johnson/parser/syntax_error'

module Johnson
  module Parser
    class << self
      def parse(js)
        tree = if js.is_a?(String)
          parse_io(StringIO.new(js))
        else
          parse_io(js)
        end
        tree.to_mutable_tree
      end

      def parse_io(js)
        Johnson::SpiderMonkey::ImmutableNode.parse_io(js)
      end
    end
  end
end
