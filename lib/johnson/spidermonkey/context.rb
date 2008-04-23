module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Context # native
      def initialize(options={})
        initialize_native(options)
        @gcthings = {}
        self["Ruby"] = Object
      end
      
      def [](key)
        global[key]
      end
      
      def []=(key, value)
        global[key] = value
      end
            
      protected
      
      def handle_js_exception(jsex)
        message = jsex.message
        message = "<no message>" if message.nil? || message.length == 0
        
        # FIXME: sanitize stack traces
        ex = Johnson::Error.new("#{jsex.name}: #{message}")
        ex.set_backtrace(jsex.stack.split("\n") + caller)
        
        raise ex
      end
      
      # called from js_land_proxy.c:make_js_land_proxy
      def add_gcthing(thing)
        @gcthings[thing.object_id] = thing
      end
      
      # called from js_land_proxy.c:finalize
      def remove_gcthing(thing)
        @gcthings.delete(thing.object_id)
      end
    end
  end
end
