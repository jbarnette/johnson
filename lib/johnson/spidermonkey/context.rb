module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Context # native
      def initialize
        @gcthings = {}
      end
            
      protected
      
      # called from JSFunction executor - js_proxy.c:call_proc
      def call_proc_by_oid(oid, *args)
        id2ref(oid).call(*args)
      end
      
      # called from JSFunction executor - js_proxy.c:unwrap
      def id2ref(oid)
        ObjectSpace._id2ref(oid)
      end
      
      # called from js_proxy.c:method_missing
      def jsend(target, symbol, args)
        block = args.pop if args.last.is_a?(RubyProxy) && args.last.function?
        target.__send__(symbol, *args, &block)
      end
      
      # called from js_proxy.c:make_js_proxy
      def add_gcthing(thing)
        @gcthings[thing.object_id] = thing
      end
      
      # called from js_proxy.c:finalize
      def remove_gcthing(thing)
        @gcthings.delete(thing.object_id)
      end
    end
  end
end
