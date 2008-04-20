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
