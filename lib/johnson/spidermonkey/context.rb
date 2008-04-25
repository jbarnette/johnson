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
        raise jsex if Exception === jsex
        raise Johnson::Error.new(jsex.to_s) unless Johnson::SpiderMonkey::RubyLandProxy === jsex
        
        # FIXME: sanitize stack traces
        stack = jsex.stack rescue nil
        
        ex = Johnson::Error.new(jsex)
        if stack
          ex.set_backtrace(stack.split("\n") + caller)
        else
          ex.set_backtrace(caller)
        end
        
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
