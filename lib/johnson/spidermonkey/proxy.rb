module Johnson
  module SpiderMonkey
    class Proxy # native
      def to_proc
        @proc ||= Proc.new { |*args| call(*args) }
      end
      
      def method_missing(sym, *args)
        # FIXME: SO much to do here
        return self[sym.to_s] if args.empty?
      end
    end
  end
end
