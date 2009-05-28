module Johnson
  module SpiderMonkey
    class RubyLandProxy
      
      include Convert

      attr_reader :js_value

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
        @js_value = JSValue.new(@runtime, value)

        @js_value.root_rt(binding, name)
        
        @runtime.send(:roots) << @js_value
        @runtime.send(:jsids)[@js_value.value] = self
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
        @js_value.root(binding) do |js_value|
          result = SpiderMonkey.JS_TypeOfValue(@context, js_value.value) == JSTYPE_FUNCTION ? true : false
        end
      end

      private

      def get(name)

        retval = FFI::MemoryPointer.new(:long)

        if name.kind_of?(Fixnum)
          SpiderMonkey.JS_GetElement(@context, @js_value.to_object, name, retval)
        else
          SpiderMonkey.JS_GetProperty(@context, @js_value.to_object, name, retval)
        end
        
        JSValue.new(@runtime, retval).to_ruby

      end

      def set(name, value)

        convert_to_js(value).root do |js_value|

          case name
          
          when Fixnum
            SpiderMonkey.JS_SetElement(@context, @js_value.to_object, name, js_value)
          else
            SpiderMonkey.JS_SetProperty(@context, @js_value.to_object, name, js_value)
          end

          value
        end

      end

      def native_call(this, *args)

        unless function?
          raise "This Johnson::SpiderMonkey::RubyLandProxy isn't a function."
        end

        global = JSValue.new(@runtime, this)
        call_js_function_value(global.to_js, @js_value, *args)

      end

      def call_js_function_value(target, function, *args)

        target_value = JSValue.new(@runtime, target)
        function_value = JSValue.new(@runtime, function)

        target_value.root(binding)
        function_value.root(binding)
        
        if SpiderMonkey.JSVAL_IS_OBJECT(target) == JS_FALSE
          raise "Target must be an object!"
        end
        
        js_args = args.map do |arg|
          arg_value = RubyValue.new(@runtime, arg).to_js
          arg_value.root(binding)
          arg_value
        end
        
        js_args_ptr = FFI::MemoryPointer.new(:long, args.size).put_array_of_int(0, js_args)

        result = FFI::MemoryPointer.new(:long)

        SpiderMonkey.JS_CallFunctionValue(@context, target.to_object, function, args.size, js_args_ptr, result)

        target_value.unroot
        function_value.unroot

        JSValue.new(@runtime, result).to_js
      end

    end
  end
end
