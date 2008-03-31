module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Context # native
      def initialize
        @gcthings = {}
      end
      
      def jsend(target, symbol, args)
        if args.last && args.last.is_a?(RubyProxy) && args.last.function?
          block = args.pop
          target.__send__(symbol, *args, &block)
        else
          target.__send__(symbol, *args)          
        end
      end
    end
  end
end
