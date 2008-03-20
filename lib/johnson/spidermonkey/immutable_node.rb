require 'stringio'

module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class ImmutableNode
      class << self
        def parse(js)
          parse_io(StringIO.new(js))
        end
      end
    end
  end
end
