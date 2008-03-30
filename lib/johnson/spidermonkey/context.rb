module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Context # native
      def initialize
        @gcthings = {}
      end
    end
  end
end
