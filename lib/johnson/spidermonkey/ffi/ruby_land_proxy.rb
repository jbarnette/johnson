module Johnson
  module SpiderMonkey
    class RubyLandProxy
      
      include Convert

      attr_reader :proxy_js_value

      class << self
        protected :new

        def make(runtime, value, name = '')
          if runtime.send(:jsids).has_key?(value)
            runtime.send(:jsids)[value]
          else
            self.new(runtime, value, name)
          end
        end
        
      end

      def initialize(runtime, value, name)
        @runtime = runtime
        @context = runtime.context
        @proxy_js_value = JSValue.new(@runtime, value)

        @proxy_js_value.root_rt(binding, name)
        
        @runtime.send(:roots) << @proxy_js_value
        @runtime.send(:jsids)[@proxy_js_value.value] = self
      end

      def [](name)
        get(name)
      end

      def []=(name, value)
        set(name, value)
      end

      def to_proc
        @proc ||= Proc.new { |*args| call(*args) }
      end

      def call(*args)
        call_using(@runtime.global, *args)
      end

      def call_using(this, *args)
        native_call(this, *args)
      end

      def function?
        @proxy_js_value.root(binding) do |js_value|
          result = SpiderMonkey.JS_TypeOfValue(@context, js_value.value) == JSTYPE_FUNCTION ? true : false
        end
      end

      private

      def get(name)

        retval = FFI::MemoryPointer.new(:long)

        if name.kind_of?(Fixnum)
          SpiderMonkey.JS_GetElement(@context, @proxy_js_value.to_object, name, retval)
        else
          SpiderMonkey.JS_GetProperty(@context, @proxy_js_value.to_object, name, retval)
        end
        
        JSValue.new(@runtime, retval).to_ruby

      end

      def set(name, value)

        convert_to_js(value).root do |js_value|

          case name
          
          when Fixnum
            SpiderMonkey.JS_SetElement(@context, @proxy_js_value.to_object, name, js_value)
          else
            SpiderMonkey.JS_SetProperty(@context, @proxy_js_value.to_object, name, js_value)
          end

          value
        end
        
      end

      def native_call(this, *args)

        unless function?
          raise "This Johnson::SpiderMonkey::RubyLandProxy isn't a function."
        end

        @proxy_js_value.root do |proxy_value|
          global = convert_to_js(this)
          call_js_function_value(global, proxy_value, *args)
        end
      end

      def call_js_function_value(target, function, *args)

        target.root(binding)
        function.root(binding)
        
        if SpiderMonkey.JSVAL_IS_OBJECT(target.value) == JS_FALSE
          raise "Target must be an object!"
        end
        
        js_value_args = args.map { |arg| convert_to_js(arg).root(binding) }
        
        js_args_ptr = FFI::MemoryPointer.new(:long, args.size).write_array_of_int(js_value_args.map { |js_value| js_value.value } )

        result = FFI::MemoryPointer.new(:long)

        SpiderMonkey.JS_CallFunctionValue(@context, target.to_object, function.value, args.size, js_args_ptr, result)

        js_value_args.each { |arg| arg.unroot }
        target.unroot
        function.unroot

        JSValue.new(@runtime, result).to_ruby
      end

    end
  end
end
