module Johnson
  module SpiderMonkey #:nodoc
    
    class Context

      include HasPointer

      attr_reader :runtime

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

      def global
        @runtime.global
      end

      private

      def initialize_native
        init_context
        init_global
        init_extensions

        @report_error_proc = method(:report_error).to_proc
        SpiderMonkey.JS_SetErrorReporter(self, @report_error_proc)

        SpiderMonkey.JS_SetVersion(self, JSVERSION_LATEST)
        SpiderMonkey.JS_SetOptions(self, JSOPTION_VAROBJFIX | JSOPTION_DONT_REPORT_UNCAUGHT)
      end

      def init_context
        @ptr = SpiderMonkey.JS_NewContext(@runtime, 8192)
      end

      def init_global
        if @runtime.has_native_global?
          @native_global = @runtime.native_global
        else
          @native_global = NativeGlobal.new(self)
        end
      end

      def define_property(js_context, obj, argc, argv, retval)

        raise 'argc must be > 1 in Context#define_property' unless argc > 1

        args = argv.get_array_of_int(0, argc)

        name = SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JSVAL_TO_STRING(args[1]))    

        flags = argc > 3 ? SpiderMonkey.JSVAL_TO_INT(args[3]) : 0

        retval.write_long(JSVAL_VOID)

        SpiderMonkey.JS_DefineProperty(js_context, 
                                       SpiderMonkey.JSVAL_TO_OBJECT(args[0]), 
                                       name, argc > 2 ? args[2] : JSVAL_VOID, 
                                       nil, 
                                       nil, 
                                       flags)
        JS_TRUE
      end

      def init_extensions

        object_value = FFI::MemoryPointer.new(:long)
        @define_property_cb = method(:define_property).to_proc

        SpiderMonkey.JS_GetProperty(self, @native_global, "Object", object_value)
        SpiderMonkey.JS_AddNamedRoot(self, object_value, 'Object')

        SpiderMonkey.JS_DefineFunction(self, 
                                       SpiderMonkey.JSVAL_TO_OBJECT(object_value.read_long),
                                       "defineProperty", 
                                       @define_property_cb, 
                                       4, 
                                       0)
        
        SpiderMonkey.JS_DefineProperty(self, 
                                       SpiderMonkey.JSVAL_TO_OBJECT(object_value.read_long),
                                       "READ_ONLY",
                                       SpiderMonkey.INT_TO_JSVAL(0x02), 
                                       nil, 
                                       nil, 
                                       JSPROP_READONLY)
        
        SpiderMonkey.JS_DefineProperty(self,
                                       SpiderMonkey.JSVAL_TO_OBJECT(object_value.read_long),
                                       "ITERABLE",
                                       SpiderMonkey.INT_TO_JSVAL(0x01), 
                                       nil, 
                                       nil, 
                                       JSPROP_READONLY)
        
        SpiderMonkey.JS_DefineProperty(self, 
                                       SpiderMonkey.JSVAL_TO_OBJECT(object_value.read_long),
                                       "NON_DELETABLE",
                                       SpiderMonkey.INT_TO_JSVAL(0x04), 
                                       nil, 
                                       nil, 
                                       JSPROP_READONLY)

        SpiderMonkey.JS_RemoveRoot(self, object_value)
      end

      def report_error(js_context, message, report)
        SpiderMonkey.JS_GetPendingException(self, exception)
      end

    end
  end
end
