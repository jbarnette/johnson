module Johnson
  module SpiderMonkey

    class JSLandProxy

      include Convert

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

        def js_value_is_proxy?(js_value)
          js_class = SpiderMonkey::JSClassReadOnly.new(SpiderMonkey.JS_GetClass(js_value.to_object))
          js_class[:name].read_string == 'JSLandClassProxy'    || \
          js_class[:name].read_string == 'JSLandProxy'         || \
          js_class[:name].read_string == 'JSLandCallableProxy'
        end

        def unwrap_js_land_proxy(runtime, js_value)
          runtime.send(:jsids)[js_value.value]
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

        @runtime.send(:rbids)[object_id] = self

        @js_object.unroot
      end
      
      private

      def js_land_class_proxy_class
        @js_land_class_proxy_class = SpiderMonkey.JSClass.allocate
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
        @js_land_proxy_class = SpiderMonkey.JSClass(:new_resolve).allocate
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
        @js_land_callable_proxy_class = SpiderMonkey.JSClass.allocate
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
      
      def get(js_context, obj, id, retval)

        JSValue.new(@runtime, id).root(binding) do |id|

          name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JSVAL_TO_STRING(id.value))

          if SpiderMonkey.JSVAL_IS_INT(id.value)
            idx = name.to_i
            if @value.respond_to?(:[])
              retval.write_long(convert_to_js(@value[idx]).read_long)
              id.unroot
              return JS_TRUE
            end
          end

          if name == '__iterator__'
            evaluate_js_property_expression("Johnson.Generator.create", retval)
            
          # elsif autovivified?(ruby, name)
          #   retval.write_long(convert_to_js(autovivified(ruby, name)).read_long)

          elsif @value.kind_of?(Class) && @value.constants.include?(name)
            retval.write_long(convert_to_js(@value.const_get(name)).read_long)

          elsif name.match(/^\$/) && global_variables.include?(name)
            retval.write_long(convert_to_js(eval(name)).value)


          # elsif attribute?(@value, name)
          #   retval.write_long(convert_to_js(@value.send(name.to_sym)).read_long)

          elsif @value.respond_to?(name.to_sym)
            retval.write_long(convert_to_js(@value.method(name.to_sym)).read_long)

          elsif @value.respond_to?(:key?) && @value.respond_to?(:[])
            if @value.key?(name)
              retval.write_long(convert_to_js(@value[name]).read_long)
            end
          end
        end
        JS_TRUE
      end

      def set
      end

      def finalize(js_context, obj)
        @runtime.send(:rbids).delete(object_id)
        JS_TRUE
      end

      def construct
      end

      def call
      end

      def resolve(js_context, obj, id, flags, objp)

        # context.root do |r|

        #   r.jroot { id }

        #   name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JS_ValueToString(js_context, id))

        #   if js_respond_to?(js_context, obj, name)
        #     r.jcheck do 
        #       SpiderMonkey.JS_DefineProperty(js_context, obj, name, JSVAL_VOID, method(:get_and_destroy_resolved_property).to_proc, 
        #                                      method(:set).to_proc, JSPROP_ENUMERATE)
        #     end
        #   end
          
        #   objp.write_pointer(obj)
          
        #   JS_TRUE

        # end
        JS_TRUE
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
