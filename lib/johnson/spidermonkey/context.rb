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
      
      # called from JSFunction executor - js_land_proxy.c:call_proc
      def call_proc_by_oid(oid, *args)
        id2ref(oid).call(*args)
      end
      
      # called from JSFunction executor - js_land_proxy.c:unwrap
      def id2ref(oid)
        ObjectSpace._id2ref(oid)
      end
      
      # called from js_land_proxy.c:method_missing
      def jsend(target, symbol, args)
        block = args.pop if args.last.is_a?(RubyLandProxy) && args.last.function?
        target.__send__(symbol, *args, &block)
      end

      # called from js_land_proxy.c:get
      def autovivified(target, attribute)
        target.send(:__johnson_js_properties)[attribute]
      end

      # called from js_land_proxy.c:get
      def autovivified?(target, attribute)
        return false unless target.respond_to?(:__johnson_js_properties)
        target.send(:__johnson_js_properties).has_key?(attribute)
      end

      # called from js_land_proxy.c:set
      def autovivify(target, attribute, value)
        (class << target; self; end).instance_eval do
          unless target.respond_to?(:__johnson_js_properties)
            define_method(:__johnson_js_properties) do
              @__johnson_js_properties ||= {}
            end
          end
          define_method(:"#{attribute}=") do |arg|
            send(:__johnson_js_properties)[attribute] = arg
          end
          define_method(:"#{attribute}") do |*args|
            js_prop = send(:__johnson_js_properties)[attribute]
            if js_prop.is_a?(RubyLandProxy) && js_prop.function?
              js_prop.call_using(self, *args)
            else
              js_prop
            end
          end
        end

        target.send(:"#{attribute}=", value)
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
