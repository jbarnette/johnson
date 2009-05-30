module Johnson
  module SpiderMonkey

    class JSLandProxy

      attr_reader :js_value

      class << self
        
        protected :new

        def make(runtime, value)          
          if runtime.send(:rbids).has_key?(value)
            runtime.send(:rbids)[value].js_value
          else
            self.new(runtime, value).js_value
          end
        end

      end

      def initialize(runtime, value)
        
        @runtime = runtime
        @context = runtime.context
        @value = value

        if @runtime.send(:rbids).has_key?(@value.object_id)
          @runtime.send(:rbids)[@value.object_id]
        else
          
          @klass = if @value.kind_of?(Class)
                     js_land_class_proxy_class
                   elsif @value.respond_to?(:call)
                     js_land_callable_proxy_class
                   else
                     js_land_proxy_class
                   end
        end

        @js_object = JSGCThing.new(@runtime, SpiderMonkey.JS_NewObject(@context, @klass, nil, nil))
        @js_object.root(binding)
        @js_value = JSValue.new(@runtime, SpiderMonkey.OBJECT_TO_JSVAL(@js_object.to_ptr))

        @js_method_missing = method(:js_method_missing).to_proc
        @toArray = method(:to_array).to_proc
        @toString = method(:to_string).to_proc

        SpiderMonkey.JS_DefineFunction(@context, @js_object, "__noSuchMethod__", @js_method_missing, 2, 0)
        SpiderMonkey.JS_DefineFunction(@context, @js_object, "toArray", @toArray, 0, 0)
        SpiderMonkey.JS_DefineFunction(@context, @js_object, "toString", @toString, 0, 0)

        @Object_id_data = FFI::MemoryPointer.new(:long_long).put_long_long(0, object_id)

        @runtime.send(:rbids)[object_id] = @js_value

        @js_object.unroot
      end
      
      private

      def js_land_class_proxy_class
        @js_land_class_proxy_class = JSClass.allocate
        @js_land_class_proxy_class.name = 'JSLandClassProxy'
        @js_land_class_proxy_class.addProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @js_land_class_proxy_class.delProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @js_land_class_proxy_class.getProperty = method(:get).to_proc
        @js_land_class_proxy_class.setProperty = method(:set).to_proc
        @js_land_class_proxy_class.enumerate = SpiderMonkey.method(:JS_EnumerateStub).to_proc
        @js_land_class_proxy_class.resolve =  SpiderMonkey.method(:JS_ResolveStub).to_proc
        @js_land_class_proxy_class.convert = SpiderMonkey.method(:JS_ConvertStub).to_proc
        @js_land_class_proxy_class.finalize = method(:finalize).to_proc
        @js_land_class_proxy_class.construct = method(:construct).to_proc

        @js_land_class_proxy_class
      end

      def js_land_proxy_class
        @js_land_proxy_class = JSClass(:new_resolve).allocate
        @js_land_proxy_class.name = 'JSLandProxy'
        @js_land_proxy_class.addProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @js_land_proxy_class.delProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @js_land_proxy_class.getProperty = method(:get).to_proc
        @js_land_proxy_class.setProperty = method(:set).to_proc
        @js_land_proxy_class.enumerate = SpiderMonkey.method(:JS_EnumerateStub).to_proc
        @js_land_proxy_class.resolve = method(:resolve).to_proc
        @js_land_proxy_class.convert = SpiderMonkey.method(:JS_ConvertStub).to_proc
        @js_land_proxy_class.finalize = method(:finalize).to_proc

        @js_land_proxy_class[:flags] = JSCLASS_NEW_RESOLVE

        @js_land_proxy_class
      end

      def js_land_callable_proxy_class
        @js_land_callable_proxy_class = JSClass.allocate
        @js_land_callable_proxy_class.name = 'JSLandCallableProxy'
        @js_land_callable_proxy_class.addProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @js_land_callable_proxy_class.delProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @js_land_callable_proxy_class.getProperty = method(:get).to_proc
        @js_land_callable_proxy_class.setProperty = method(:set).to_proc
        @js_land_callable_proxy_class.enumerate = SpiderMonkey.method(:JS_EnumerateStub).to_proc
        @js_land_callable_proxy_class.resolve =  SpiderMonkey.method(:JS_ResolveStub).to_proc
        @js_land_callable_proxy_class.convert = SpiderMonkey.method(:JS_ConvertStub).to_proc
        @js_land_callable_proxy_class.finalize = method(:finalize).to_proc
        @js_land_callable_proxy_class.construct = method(:construct).to_proc
        @js_land_callable_proxy_class.call = method(:call).to_proc
        @js_land_callable_proxy_class
      end
      
      def get
      end

      def set
      end

      def finalize(js_context, obj)

        JS_TRUE
      end

      def construct
      end

      def call
      end

      def resolve
      end

      def to_array
      end

      def to_string
      end
      
      def js_method_missing
      end

    end
  end
end
