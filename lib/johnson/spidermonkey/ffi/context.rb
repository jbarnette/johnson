module Johnson
  module SpiderMonkey #:nodoc
    
    class Context

      include HasPointer

      attr_reader :runtime, :global
      attr_accessor :pending_js_ex_message, :root_names

      def initialize(runtime, options={})
        @runtime = runtime
        initialize_native
      end

      def has_exception?
        true if @exception && !@exception.null?
      end

      def exception
        @exception ||= FFI::MemoryPointer.new(:long) 
      end

      private

      def initialize_native
        init_context
        init_global
        init_extensions

        SpiderMonkey.JS_SetErrorReporter(self, method(:report_error).to_proc)
        SpiderMonkey.JS_SetVersion(self, JSVERSION_LATEST)
        SpiderMonkey.JS_SetOptions(self, JSOPTION_VAROBJFIX | JSOPTION_DONT_REPORT_UNCAUGHT)
      end

      def init_context
        @ptr = SpiderMonkey.JS_NewContext(@runtime, 8192)
      end

      def init_global
        if @runtime.has_global?
          @global = @runtime.global
        else
          @global = Global.new(self)
        end
      end

      def define_property(js_context, obj, argc, argv, retval)
        args = argv.get_array_of_int(0, argc)
        flags = argc > 3 ? SpiderMonkey.JSVAL_TO_INT(args[3]) : 0
        retval.write_long(JSVAL_VOID)
        name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JS_ValueToString(js_context, args[1]))    
        js_object = FFI::MemoryPointer.new(:pointer)
        SpiderMonkey.JS_ValueToObject(js_context, args[0], js_object)
        SpiderMonkey.JS_DefineProperty(js_context, js_object.read_pointer, name, argc > 2 ? args[2] : JSVAL_VOID, nil, nil, flags)
      end

      def init_extensions
        object = FFI::MemoryPointer.new(:long)
        object_ptr = FFI::MemoryPointer.new(:pointer)

        SpiderMonkey.JS_GetProperty(self, @global, "Object", object)

        SpiderMonkey.JS_ValueToObject(self, object.read_long , object_ptr)

        SpiderMonkey.JS_DefineFunction(self, 
                                       object_ptr.read_pointer,
                                       "defineProperty", 
                                       method(:define_property).to_proc, 
                                       4, 
                                       0)
        
        SpiderMonkey.JS_DefineProperty(self, 
                                       object_ptr.read_pointer, 
                                       "READ_ONLY",
                                       SpiderMonkey.INT_TO_JSVAL(0x02), 
                                       nil, 
                                       nil, 
                                       JSPROP_READONLY)
        
        SpiderMonkey.JS_DefineProperty(self, 
                                       object_ptr.read_pointer, 
                                       "ITERABLE",
                                       SpiderMonkey.INT_TO_JSVAL(0x01), 
                                       nil, 
                                       nil, 
                                       JSPROP_READONLY)
        
        SpiderMonkey.JS_DefineProperty(self, 
                                       object_ptr.read_pointer, 
                                       "NON_DELETABLE",
                                       SpiderMonkey.INT_TO_JSVAL(0x04), 
                                       nil, 
                                       nil, 
                                       JSPROP_READONLY)

      end

      def report_error(js_context, message, report)
        SpiderMonkey.JS_GetPendingException(self, exception)
      end

    end
  end
end
