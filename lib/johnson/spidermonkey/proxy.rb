module Johnson
  module SpiderMonkey
    
    # Also see ext/spidermonkey/proxy.c
    class Proxy
      def method_missing(sym, *args)
        return self[sym.to_s] if args.empty?
      end
    end
  end
end
