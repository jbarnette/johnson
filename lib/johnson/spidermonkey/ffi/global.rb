module Johnson
  module SpiderMonkey

    class NativeGlobal
      
      include HasPointer

      def initialize(js_context)
        @js_context = js_context

        @global_class = JSClassWithNewResolve.allocate
        @global_class.name = 'global'
        @global_class[:flags] = JSCLASS_NEW_RESOLVE | JSCLASS_GLOBAL_FLAGS
        @global_class.addProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @global_class.delProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @global_class.getProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @global_class.setProperty = SpiderMonkey.method(:JS_PropertyStub).to_proc
        @global_class.enumerate = method(:enumerate).to_proc
        @global_class.resolve = method(:resolve).to_proc
        @global_class.convert = SpiderMonkey.method(:JS_ConvertStub).to_proc
        @global_class.finalize = SpiderMonkey.method(:JS_FinalizeStub).to_proc
        
        @ptr = SpiderMonkey.JS_NewObject(@js_context, @global_class, nil, nil)
      end

      def enumerate(js_context, obj)
        JS_EnumerateStandardClasses(js_context, obj)
      end

      def resolve(js_context, obj, id, flags, objp)
        if ((flags & JSRESOLVE_ASSIGNING) == 0)
          resolved_p = FFI::MemoryPointer.new(:int)
          if (!SpiderMonkey.JS_ResolveStandardClass(js_context, obj, id, resolved_p) == JS_TRUE)
            return JS_FALSE
          end
          if resolved_p.get_int(0) == JS_TRUE
            objp.write_pointer(obj)
          end
        end
        JS_TRUE
      end

    end

  end
end
