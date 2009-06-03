module Johnson
  module SpiderMonkey

    class JSLandProxy

      class << self
        
        def make(runtime, value)          
          if runtime.send(:rbids).has_key?(value.__id__)
            JSValue.new(runtime, runtime.send(:rbids)[value.__id__])
          else
            context = runtime.context

            if runtime.send(:rbids).has_key?(value.__id__)
              runtime.send(:rbids)[value.__id__]
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

            @js_method_missing = method(:js_method_missing).to_proc
            @toArray = method(:to_array).to_proc
            @toString = method(:to_string).to_proc

            SpiderMonkey.JS_DefineFunction(context, js_object, "__noSuchMethod__", @js_method_missing, 2, 0)
            SpiderMonkey.JS_DefineFunction(context, js_object, "toArray", @toArray, 0, 0)
            SpiderMonkey.JS_DefineFunction(context, js_object, "toString", @toString, 0, 0)
            
            runtime.send(:rbids)[value.__id__] = js_value.value
            private_data = FFI::MemoryPointer.new(:long).write_long(value.__id__)
            runtime.add_gcthing(value.__id__, [value, private_data])
            SpiderMonkey.JS_SetPrivate(context, js_object, private_data)
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

        def get_ruby_id(context, js_object)
          SpiderMonkey.JS_GetInstancePrivate(context, js_object, SpiderMonkey.JS_GetClass(js_object), nil).read_long
        end

        def get_ruby_object(context, js_object)
          ObjectSpace._id2ref(get_ruby_id(context, js_object))
        end

        def get_runtime(js_context)
          SpiderMonkey.runtimes[SpiderMonkey.JS_GetRuntime(js_context).address]
        end

        def get(js_context, obj, id, retval)

          ruby_object = get_ruby_object(js_context, obj)
          runtime = get_runtime(js_context)

          JSValue.new(runtime, id).root(binding) do |id|
            
            if SpiderMonkey.JSVAL_IS_INT(id.value)
              idx = SpiderMonkey.JSVAL_TO_INT(id.value)
              if ruby_object.respond_to?(:[])
                retval.write_long(Convert.to_js(runtime, ruby_object[idx]).value)
                id.unroot
                return JS_TRUE
              end
            end

            name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JSVAL_TO_STRING(id.value))
            
            if name == '__iterator__'
              evaluate_js_property_expression(runtime, "Johnson.Generator.create", retval)

            elsif autovivified?(ruby_object, name)
              retval.write_long(Convert.to_js(runtime, autovivified(ruby_object, name)).value)

            elsif ruby_object.kind_of?(Class) && ruby_object.constants.include?(name)
              retval.write_long(Convert.to_js(runtime, ruby_object.const_get(name)).value)

            elsif name.match(/^\$/) && global_variables.include?(name)
              retval.write_long(Convert.to_js(runtime, eval(name)).value)

            elsif attribute?(ruby_object, name)
              retval.write_long(Convert.to_js(runtime, ruby_object.send(name.to_sym)).value)

            elsif ruby_object.respond_to?(:key?) && ruby_object.respond_to?(:[]) && ruby_object.key?(name)
              retval.write_long(Convert.to_js(runtime, ruby_object[name]).value)

            elsif ruby_object.respond_to?(name.to_sym)
              retval.write_long(Convert.to_js(runtime, ruby_object.method(name.to_sym)).value)
            end
          end
          JS_TRUE
        end

        def set(js_context, obj, id, vp)
          
          ruby_object = get_ruby_object(js_context, obj)
          runtime = get_runtime(js_context)
          
          id_value = JSValue.new(runtime, id).root(binding)
          vp_value = JSValue.new(runtime, vp).root(binding)
          
          if SpiderMonkey::JSVAL_IS_INT(id)
            idx = SpiderMonkey.JSVAL_TO_INT(id_value.value)
            if ruby_object.respond_to?(:[]=)
              ruby_object[idx] = vp_value.to_ruby
            end

            id_value.unroot
            vp_value.unroot

            return JS_TRUE
          end

          name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JSVAL_TO_STRING(id))          

          ruby_key = Convert.to_ruby(runtime, id_value)
          ruby_value = Convert.to_ruby(runtime, vp_value)

          setter = "#{ruby_key}=".to_sym
          settable = ruby_object.respond_to?(setter)
          indexable = ruby_object.respond_to?(:[]=)

          if settable
            setter_method = ruby_object.method(setter)
            setter_arity = setter_method.arity

            # FIXME: Accessors arity in JRuby is -1 instead of 1. The
            # problem was submitted to the author meanwhile we fix the
            # issue with a conditional branch.
            unless RUBY_PLATFORM =~ /java/
              if setter_arity == 1
                ruby_object.send(setter, ruby_value)
              end
            else
              ruby_object.send(setter, ruby_value)
            end

          elsif indexable
            ruby_object.send(:[]=, name, Convert.to_ruby(runtime, vp_value))
          else
            autovivify(ruby_object, name, Convert.to_ruby(runtime, vp_value))
          end

          id_value.unroot
          vp_value.unroot

          JS_TRUE
        end

        def finalize(js_context, obj)
          runtime = SpiderMonkey.runtimes[SpiderMonkey.JS_GetRuntime(js_context).address]
          ruby_object = get_ruby_object(js_context, obj)

          runtime.send(:rbids).delete(ruby_object.__id__)
          runtime.remove_gcthing(ruby_object.__id__)

          JS_TRUE
        end

        def construct(js_context, obj, argc, argv, retval)

          runtime = get_runtime(js_context)

          klass = JSValue.new(runtime, SpiderMonkey.JS_ARGV_CALLEE(argv)).to_ruby

          args = argv.read_array_of_int(argc).collect do |js_value|
            JSValue.new(runtime, js_value).to_ruby
          end

          call_ruby_from_js(js_context, retval, klass, :new, args)
        end

        def call(js_context, obj, argc, argv, retval)

          runtime = get_runtime(js_context)

          self_id = SpiderMonkey.JS_GetInstancePrivate(js_context, 
                                                       SpiderMonkey.JSVAL_TO_OBJECT(SpiderMonkey.JS_ARGV_CALLEE(argv)), 
                                                       JSLandCallableProxyClass(), nil).read_int
          self_value = ObjectSpace._id2ref(self_id)

          args = argv.read_array_of_int(argc).collect do |js_value|
            JSValue.new(runtime, js_value).to_ruby
          end
          
          call_ruby_from_js(js_context, retval, self_value, :call, args)
        end

        def resolve(js_context, obj, id, flags, objp)
          
          runtime = get_runtime(js_context)

          JSValue.new(runtime, id).root(binding) do |id_value|
            name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JS_ValueToString(js_context, id_value.value))
            if js_respond_to?(js_context, obj, name)
              SpiderMonkey.JS_DefineProperty(js_context, obj, name, JSVAL_VOID, method(:get_and_destroy_resolved_property).to_proc, 
                                             method(:set).to_proc, JSPROP_ENUMERATE)
              objp.write_pointer(obj)
            end
            JS_TRUE
          end

        end

        def to_array(js_context, obj, argc, argv, retval)

          runtime = get_runtime(js_context)
          ruby_object = get_ruby_object(js_context, obj)

          retval.write_long(Convert.to_js(runtime, ruby_object.to_a).value)
          JS_TRUE
        end

        def to_string
          
        end
        
        def js_method_missing(js_context, obj, argc, argv, retval)
          runtime = get_runtime(js_context)
          ruby_object = get_ruby_object(js_context, obj)

          args = argv.read_array_of_int(argc)
          args.collect! do |js_value|
            JSValue.new(runtime, js_value).to_ruby
          end

          method_name = args[0]

          params = args[1].to_a

          call_ruby_from_js(js_context, retval, ruby_object, method_name, params)
        end

        def js_respond_to?(js_context, obj, name)
          ruby_object = get_ruby_object(js_context, obj)

          autovivified?(ruby_object, name) || \
          constant?(ruby_object, name)     || \
          global?(name)                    || \
          attribute?(ruby_object, name)    || \
          method?(ruby_object, name)       || \
          has_key?(ruby_object, name)
        end

        def evaluate_js_property_expression(runtime, property, retval)

          SpiderMonkey.JS_EvaluateScript(runtime.context, 
                                         runtime.native_global,
                                         property, 
                                         property.size, 
                                         "johnson:evaluate_js_property_expression", 1,
                                         retval)
        end

        def get_and_destroy_resolved_property(js_context, obj, id, retval)
          runtime = get_runtime(js_context)

          ruby_object = unless runtime.gc_thing?(get_ruby_id(runtime, obj))
                          JSValue.new(runtime, SpiderMonkey.OBJECT_TO_JSVAL(obj)).to_ruby
                        else
                          get_ruby_object(runtime, obj)
                        end

          JSValue.new(runtime, id).root(binding) do |id_value|

            name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JSVAL_TO_STRING(id_value.value))
            SpiderMonkey.JS_DeleteProperty(js_context, obj, name)
            if ruby_object.kind_of?(RubyLandProxy)
              retval.write_long(Convert.to_js(runtime, ruby_object[name]).value)
            else
              get(js_context, obj, id, retval)
            end
            JS_TRUE
          end
        end

        def global?(name)
          name.match(/^\$/) && global_variables.include?(name)
        end

        def constant?(target, name)
          target.kind_of?(Class) && target.constants.include?(name)
        end

        def method?(target, name)
          target.respond_to?(name.to_sym)          
        end
        
        def has_key?(target, name)
          target.respond_to?(:key?) and target.respond_to?(:[]) and target.key?(name)
        end

        def call_ruby_from_js(js_context, retval, target, symbol, args)
          begin
            retval.write_long(Convert.to_js(get_runtime(js_context), send_with_possible_block(target, symbol, args)).value)
            JS_TRUE
          rescue Exception => ex
            SpiderMonkey.JS_SetPendingException(js_context, Convert.to_js(get_runtime(js_context), ex).value)
            JS_FALSE
          end
        end

        def send_with_possible_block(target, symbol, args)
          block = args.pop if args.last.is_a?(RubyLandProxy) && args.last.function?
          target.__send__(symbol, *args, &block)
        end
        
        def treat_all_properties_as_methods(target)
          def target.js_property?(name); true; end
        end

        def attribute?(target, name)
          if target.respond_to?(name.to_sym)
            target.instance_variables.include?("@#{name}")
          end
        end      

        def js_property?(target, name)
          # FIXME: that rescue is gross; handles, e.g., "name?"
          (target.send(:instance_variable_defined?, "@#{name}") rescue false) ||
          (target.respond_to?(:js_property?) && target.__send__(:js_property?, name))
        end
        
        def call_proc_by_oid(oid, *args)
          id2ref(oid).call(*args)
        end
                
        def autovivified(target, attribute)
          target.send(:__johnson_js_properties)[attribute]
        end

        def autovivified?(target, attribute)
          target.respond_to?(:__johnson_js_properties) &&
            target.send(:__johnson_js_properties).key?(attribute)
        end

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

      end

      
    end
  end
end
