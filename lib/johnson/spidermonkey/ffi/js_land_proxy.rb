module Johnson
  module SpiderMonkey

    class JSLandProxy

      class << self
        
        def make(runtime, value)          
          if runtime.send(:rbids).has_key?(value)
            runtime.send(:rbids)[value].js_value
          else
            context = runtime.context

            if runtime.send(:rbids).has_key?(value.object_id)
              runtime.send(:rbids)[value.object_id]
            else
              
              klass = if value.kind_of?(Class)
                        JSLandClassProxyClass()
                      elsif value.respond_to?(:call)
                        JSLandCallableProxyClass()
                      else
                        JSLandProxyClass()
                      end
            end

            js_object = JSGCThing.new(runtime, SpiderMonkey.JS_NewObject(context, klass, nil, nil))
            js_object.root(binding)
            js_value = JSValue.new(runtime, SpiderMonkey.OBJECT_TO_JSVAL(js_object.to_ptr))

            @method_missing = method(:method_missing).to_proc
            @toArray = method(:to_array).to_proc
            @toString = method(:to_string).to_proc

            SpiderMonkey.JS_DefineFunction(context, js_object, "__noSuchMethod__", @method_missing, 2, 0)
            SpiderMonkey.JS_DefineFunction(context, js_object, "toArray", @toArray, 0, 0)
            SpiderMonkey.JS_DefineFunction(context, js_object, "toString", @toString, 0, 0)

            SpiderMonkey.JS_SetPrivate(context, js_object, FFI::MemoryPointer.new(:int).write_int(value.object_id))

            runtime.send(:rbids)[value.object_id] = js_value.value
            runtime.add_gcthing(value)

            js_object.unroot
            js_value
          end
        end

        def js_value_is_proxy?(js_value)
          js_class = SpiderMonkey.JS_GetClass(js_value.to_object)
          js_class == JSLandClassProxyClass().to_ptr    || \
          js_class == JSLandProxyClass().to_ptr         || \
          js_class == JSLandCallableProxyClass().to_ptr
        end

        def unwrap_js_land_proxy(runtime, js_value)
          get_ruby_object(runtime.context, js_value.to_object)
        end

        private

        def JSLandClassProxyClass

          return @js_land_class_proxy_class if defined? @js_land_class_proxy_class

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

          @js_land_class_proxy_class[:flags] = JSCLASS_HAS_PRIVATE

          @js_land_class_proxy_class
        end

        def JSLandProxyClass

          return @js_land_proxy_class if defined? @js_land_proxy_class

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

          @js_land_proxy_class[:flags] = JSCLASS_NEW_RESOLVE | JSCLASS_HAS_PRIVATE

          @js_land_proxy_class
        end

        def JSLandCallableProxyClass

          return @js_land_callable_proxy_class if defined? @js_land_callable_proxy_class

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

          @js_land_callable_proxy_class[:flags] = JSCLASS_HAS_PRIVATE

          @js_land_callable_proxy_class
        end

        def get_ruby_object(context, js_object)
          ruby_id = SpiderMonkey.JS_GetInstancePrivate(context, js_object, SpiderMonkey.JS_GetClass(js_object), nil).read_int
          ObjectSpace._id2ref(ruby_id)
        end

        def get_runtime(js_context)
          SpiderMonkey.runtimes[SpiderMonkey.JS_GetRuntime(js_context).address]
        end

        def get(js_context, obj, id, retval)
          
          ruby_object = get_ruby_object(js_context, obj)
          runtime = get_runtime(js_context)

          JSValue.new(runtime, id).root(binding) do |id|

            name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JSVAL_TO_STRING(id.value))

            if SpiderMonkey.JSVAL_IS_INT(id.value)
              idx = name.to_i
              if ruby_object.respond_to?(:[])
                retval.write_long(Convert.to_js(runtime, ruby_object[idx]).read_long)
                id.unroot
                return JS_TRUE
              end
            end

            if name == '__iterator__'
              evaluate_js_property_expression("Johnson.Generator.create", retval)
              
              # elsif autovivified?(ruby, name)
              #   retval.write_long(convert_to_js(autovivified(ruby, name)).read_long)

            elsif ruby_object.kind_of?(Class) && ruby_object.constants.include?(name)
              retval.write_long(Convert.to_js(runtime, ruby_object.const_get(name)).read_long)

            elsif name.match(/^\$/) && global_variables.include?(name)
              retval.write_long(Convert.to_js(runtime, eval(name)).value)


              # elsif attribute?(@value, name)
              #   retval.write_long(convert_to_js(@value.send(name.to_sym)).read_long)

            elsif ruby_object.respond_to?(name.to_sym)
              retval.write_long(Convert.to_js(runtime, ruby_object.method(name.to_sym)).read_long)

            elsif ruby_object.respond_to?(:key?) && ruby_object.respond_to?(:[])
              if ruby_object.key?(name)
                retval.write_long(Convert.to_js(runtime, ruby_object[name]).read_long)
              end
            end
          end
          JS_TRUE
        end

        def set
        end

        def finalize(js_context, obj)
          runtime = SpiderMonkey.runtimes[SpiderMonkey.JS_GetRuntime(js_context).address]
          runtime.send(:rbids).delete(object_id)
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
end
