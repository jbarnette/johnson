module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Context # native
      def initialize
        @gcthings = {}
      end
      
      def jsend(target, symbol, args)
        block = args.pop if args.last.is_a?(RubyProxy) && args.last.function?
        target.__send__(symbol, *args, &block)
      end
    end
  end
end
