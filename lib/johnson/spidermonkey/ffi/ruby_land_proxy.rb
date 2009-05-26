module Johnson
  module SpiderMonkey
    class RubyLandProxy

      attr_reader :js_value

      @roots = {}

      class << self
        protected :new

        def make(context, value, name = '')
          self.new(context, value, name)
        end

        def add_proxy_to_roots(id, js_value)
          @roots[id] = js_value
        end

        def finalize_proxy_in_roots
          @roots.each_value { |js_value| js_value.unroot }
        end
      end

      def initialize(runtime, value, name)
        @runtime = runtime
        @context = @runtime.context
        @js_value = JSValue.new(@context, value)

        @js_value.root_rt
        self.class.add_proxy_to_roots(object_id, @js_value)
      end

      def [](name)
        get(name)
      end

      def []=(name, value)
        set(name, value)
      end

      def get(name)

        retval = FFI::MemoryPointer.new(:long)

        if name.kind_of?(Fixnum)
          SpiderMonkey.JS_GetElement(@context, @js_value.to_object, name, retval)
        else
          SpiderMonkey.JS_GetProperty(@context, @js_value.to_object, name, retval)
        end
        
        JSValue.new(@context, retval).to_ruby

      end

      def set(name, value)

        ruby_value = RubyValue.new(@context, value)

        case name
          
        when Fixnum
          SpiderMonkey.JS_SetElement(@context, @js_value.to_object, name, ruby_value.to_js)
        else
          SpiderMonkey.JS_SetProperty(@context, @js_value.to_object, name, ruby_value.to_js)
        end

        value

      end

      def function?
        @js_value.root(binding)
        result = SpiderMonkey.JS_TypeOfValue(@context, @js_value.value) == JSTYPE_FUNCTION ? true : false
        @js_value.unroot
        result
      end

    end
  end
end
