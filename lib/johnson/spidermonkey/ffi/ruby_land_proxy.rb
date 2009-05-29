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

      def respond_to?(sym)
        name = sym.to_s

        return true if name.match(/=$/)

        found = FFI::MemoryPointer.new(:pointer)

        @proxy_js_value.root(binding)
        js_object = @proxy_js_value.to_object.root

        SpiderMonkey.JS_HasProperty(@context, js_object, name, found)

        @proxy_js_value.unroot
        js_object.unroot

        found.read_int == JS_TRUE ? true : super 
      end

      def method_missing(sym, *args, &block)
        args << block if block_given?
        
        name = sym.to_s
        assignment = "=" == name[-1, 1]

        # default behavior if the slot's not there

        return super unless assignment || respond_to?(sym)

        unless function_property?(name)
          # for arity 0, treat it as a get
          return self[name] if args.empty?

          # arity 1 and quacking like an assignment, treat it as a set
          return self[name[0..-2]] = args[0] if assignment && 1 == args.size
        end        
        
        # okay, must really be a function
        call_function_property(name, *args)
      end

      private

      def call_function_property(name, *args)

        @proxy_js_value.root(binding)
        js_object = @proxy_js_value.to_object.root(binding)

        function = FFI::MemoryPointer.new(:long)
          
        SpiderMonkey.JS_GetProperty(@context, js_object, name, function)
        
        function_value = JSValue(@runtime, function).root

        funtype = SpiderMonkey.JS_TypeOfValue(@context, function_value.value)

        # FIXME: should raise an error if the property is not a function
        if (funtype == JSTYPE_FUNCTION)
          result = call_using(@proxy_js_value, *args)
        end

        @proxy_js_value.unroot
        js_object.unroot
        function_value.unroot

        result
      end

      def function_property?(name)
        property = FFI::MemoryPointer.new(:pointer)
        js_object = @proxy_js_value.to_object.root(binding)

        SpiderMonkey.JS_GetProperty(@context, js_object, name, property)
        property_value = JSValue.new(@runtime, property).root(binding)

        type = SpiderMonkey.JS_TypeOfValue(@context, property_value.value)

        js_object.unroot
        property_value.unroot
       
        type == SpiderMonkey::JSTYPE_FUNCTION ? true : false
      end

      def get(name)
        @proxy_js_value.root(binding) do |proxy_value|

          retval = FFI::MemoryPointer.new(:long)

          if name.kind_of?(Fixnum)
            SpiderMonkey.JS_GetElement(@context, proxy_value.to_object, name, retval)
          else
            SpiderMonkey.JS_GetProperty(@context, proxy_value.to_object, name, retval)
          end

          JSValue.new(@runtime, retval).to_ruby
        end
      end

      def set(name, value)

        @proxy_js_value.root(binding)

        convert_to_js(value).root do |js_value|

          case name
          
          when Fixnum
            SpiderMonkey.JS_SetElement(@context, @proxy_js_value.to_object, name, js_value)
          else
            SpiderMonkey.JS_SetProperty(@context, @proxy_js_value.to_object, name, js_value)
          end

        end

        @proxy_js_value.unroot
        value
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
