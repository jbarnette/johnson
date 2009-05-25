require 'rubygems'
require 'ffi'

module Johnson
  module SpiderMonkey

    extend FFI::Library
    ffi_lib '/usr/local/lib/libmozjs.so'

    # libc
    attach_function :calloc, [ :int, :int ], :pointer
    attach_function :free, [ :pointer ], :void
    attach_function :memcpy, [ :pointer, :pointer, :int ], :pointer

    # Shutdown
    attach_function :JS_ShutDown, [  ], :void

    # Runtime
    attach_function :JS_NewRuntime, :JS_Init, [ :uint ], :pointer
    attach_function :JS_DestroyRuntime, :JS_Finish, [ :pointer ], :void

    # Context
    attach_function :JS_NewContext, [ :pointer, :uint ], :pointer
    attach_function :JS_DestroyContext, [ :pointer ], :void

    # Global
    attach_function :JS_GetGlobalObject, [ :pointer ], :pointer
    attach_function :JS_SetGlobalObject, [ :pointer, :pointer ], :void

    # Requests
    attach_function :JS_BeginRequest, [ :pointer ], :void
    attach_function :JS_EndRequest, [ :pointer ], :void

    # GC
    attach_function :JS_SetGCZeal, [ :pointer, :uchar ], :void
    attach_function :JS_MaybeGC, [ :pointer ], :void
    attach_function :JS_GC, [ :pointer ], :void

    # callback(:JSBranchCallback, [ :pointer, :pointer ], :int)
    # attach_function :JS_SetBranchCallback, [ :pointer, :JSBranchCallback ], :JSBranchCallback

    # Options

    attach_function :JS_SetOptions, [ :pointer, :uint ], :uint

    # Object

    attach_function :JS_HasInstance, [ :pointer, :pointer, :long, :pointer ], :int

    # Roots

    attach_function :JS_AddRoot, [ :pointer, :pointer ], :int
    attach_function :JS_AddNamedRoot, [ :pointer, :pointer, :pointer ], :int
    attach_function :JS_AddNamedRootRT, [ :pointer, :pointer, :pointer ], :int
    attach_function :JS_RemoveRoot, [ :pointer, :pointer ], :int
    attach_function :JS_RemoveRootRT, [ :pointer, :pointer ], :int

    # Conversions

    # The two functions below were added by me.
    # attach_function :JS_StringToValue, [ :pointer, :pointer ], :long
    # attach_function :JS_ObjectToValue, [ :pointer, :pointer ], :long

    attach_function :JS_ValueToString, [ :pointer, :long ], :pointer
    attach_function :JS_ValueToNumber, [ :pointer, :long, :pointer ], :int
    attach_function :JS_ValueToObject, [ :pointer, :long, :pointer ], :int
    attach_function :JS_ValueToId, [ :pointer, :long, :pointer ], :int
    attach_function :JS_IdToValue, [ :pointer, :long, :pointer ], :int

    attach_function :JS_TypeOfValue, [ :pointer, :long ], :int

    # String

    attach_function :JS_GetStringBytes, [ :pointer ], :string

    attach_function :JS_NewStringCopyN, [ :pointer, :string, :uint ], :pointer
    attach_function :JS_NewNumberValue, [ :pointer, :double, :pointer ], :int
    attach_function :JS_NewObject, [ :pointer, :pointer, :pointer, :pointer ], :pointer

    attach_function :JS_Enumerate, [ :pointer, :pointer ], :pointer

    callback(:JSPropertyOp, [ :pointer, :pointer, :long, :pointer ], :int)
    callback(:JSNewEnumerateOp, [ :pointer, :pointer, :int, :pointer, :pointer ], :int)
    callback(:JSEnumerateOp, [ :pointer, :pointer ], :int)
    callback(:JSResolveOp, [ :pointer, :pointer, :long ], :int)
    callback(:JSNewResolveOp, [ :pointer, :pointer, :long, :uint, :pointer ], :int)
    callback(:JSConvertOp, [ :pointer, :pointer, :int, :pointer ], :int)
    callback(:JSFinalizeOp, [ :pointer, :pointer ], :void)
    callback(:JSStringFinalizeOp, [ :pointer, :pointer ], :void)
    callback(:JSGetObjectOps, [ :pointer, :pointer ], :pointer)
    callback(:JSCheckAccessOp, [ :pointer, :pointer, :long, :int, :pointer ], :int)
    callback(:JSXDRObjectOp, [ :pointer, :pointer ], :int)
    callback(:JSHasInstanceOp, [ :pointer, :pointer, :long, :pointer ], :int)
    callback(:JSMarkOp, [ :pointer, :pointer, :pointer ], :uint)
    callback(:JSTraceOp, [ :pointer, :pointer ], :void)
    callback(:JSTraceCallback, [ :pointer, :pointer, :uint ], :void)
    callback(:JSReserveSlotsOp, [ :pointer, :pointer ], :uint)
    callback(:JSNewObjectMapOp, [ :pointer, :int, :pointer, :pointer, :pointer ], :pointer)
    callback(:JSObjectMapOp, [ :pointer, :pointer ], :void)
    callback(:JSLookupPropOp, [ :pointer, :pointer, :long, :pointer, :pointer ], :int)
    callback(:JSDefinePropOp, [ :pointer, :pointer, :long, :long, :JSPropertyOp, :JSPropertyOp, :uint, :pointer ], :int)
    callback(:JSPropertyIdOp, [ :pointer, :pointer, :long, :pointer ], :int)
    callback(:JSAttributesOp, [ :pointer, :pointer, :long, :pointer, :pointer ], :int)
    callback(:JSCheckAccessIdOp, [ :pointer, :pointer, :long, :int, :pointer, :pointer ], :int)
    callback(:JSObjectOp, [ :pointer, :pointer ], :pointer)
    callback(:JSIteratorOp, [ :pointer, :pointer, :int ], :pointer)
    callback(:JSPropertyRefOp, [ :pointer, :pointer, :pointer ], :void)
    callback(:JSSetObjectSlotOp, [ :pointer, :pointer, :uint, :pointer ], :int)
    callback(:JSGetRequiredSlotOp, [ :pointer, :pointer, :uint ], :long)
    callback(:JSSetRequiredSlotOp, [ :pointer, :pointer, :uint, :long ], :int)
    callback(:JSGetMethodOp, [ :pointer, :pointer, :long, :pointer ], :pointer)
    callback(:JSSetMethodOp, [ :pointer, :pointer, :long, :pointer ], :int)
    callback(:JSEnumerateValuesOp, [ :pointer, :pointer, :int, :pointer, :pointer, :pointer ], :int)
    callback(:JSEqualityOp, [ :pointer, :pointer, :long, :pointer ], :int)
    callback(:JSConcatenateOp, [ :pointer, :pointer, :long, :pointer ], :int)
    callback(:JSNative, [ :pointer, :pointer, :uint, :pointer, :pointer ], :int)
    callback(:JSFastNative, [ :pointer, :uint, :pointer ], :int)
    
    callback(:JSErrorReporter, [ :pointer, :string, :pointer ], :void)
    attach_function :JS_SetErrorReporter, [ :pointer, :JSErrorReporter ], :JSErrorReporter
    
    # Property

    attach_function :JS_GetProperty, [ :pointer, :pointer, :string, :pointer ], :int
    attach_function :JS_DefineProperty, [ :pointer, :pointer, :string, :long, :JSPropertyOp, :JSPropertyOp, :uint ], :int
    attach_function :JS_DeleteProperty, [ :pointer, :pointer, :string ], :int
    attach_function :JS_SetProperty, [ :pointer, :pointer, :string, :pointer ], :int
    attach_function :JS_HasProperty, [ :pointer, :pointer, :string, :pointer ], :int

    attach_function :JS_GetElement, [ :pointer, :pointer, :int, :pointer ], :int
    attach_function :JS_SetElement, [ :pointer, :pointer, :int, :pointer ], :int

    # Script

    attach_function :JS_CompileScript, [ :pointer, :pointer, :string, :uint, :string, :uint ], :pointer
    attach_function :JS_ExecuteScript, [ :pointer, :pointer, :pointer, :pointer ], :int
    attach_function :JS_EvaluateScript, [ :pointer, :pointer, :string, :uint, :string, :uint, :pointer ], :int

    # Standard classes

    attach_function :JS_EnumerateStandardClasses, [ :pointer, :pointer ], :int
    attach_function :JS_InitStandardClasses, [ :pointer, :pointer ], :int
    attach_function :JS_ResolveStandardClass, [ :pointer, :pointer, :long, :pointer ], :int

    attach_function :JS_SetVersion, [ :pointer, :int ], :int

    attach_function :JS_DefineFunction, [ :pointer, :pointer, :string, :JSNative, :uint, :uint ], :pointer

    # Exceptions

    attach_function :JS_IsExceptionPending, [ :pointer ], :int
    attach_function :JS_GetPendingException, [ :pointer, :pointer ], :int
    attach_function :JS_SetPendingException, [ :pointer, :long ], :void
    attach_function :JS_ClearPendingException, [ :pointer ], :void
    attach_function :JS_ReportPendingException, [ :pointer ], :int

    # Errors

    class JSErrorReport < FFI::Struct
      layout(
             :filename, :pointer,
             :lineno, :uint,
             :linebuf, :pointer,
             :tokenptr, :pointer,
             :uclinebuf, :pointer,
             :uctokenptr, :pointer,
             :flags, :uint,
             :errorNumber, :uint,
             :ucmessage, :pointer,
             :messageArgs, :pointer
             )
      def filename=(str)
        @filename = FFI::MemoryPointer.from_string(str)
        self[:filename] = @filename
      end
      def filename
        @filename.get_string(0)
      end
      def linebuf=(str)
        @linebuf = FFI::MemoryPointer.from_string(str)
        self[:linebuf] = @linebuf
      end
      def linebuf
        @linebuf.get_string(0)
      end
      def tokenptr=(str)
        @tokenptr = FFI::MemoryPointer.from_string(str)
        self[:tokenptr] = @tokenptr
      end
      def tokenptr
        @tokenptr.get_string(0)
      end

    end

    # Function

    attach_function :JS_CallFunctionValue, [ :pointer, :pointer, :long, :uint, :pointer, :pointer ], :int
    attach_function :JS_CallFunctionName, [ :pointer, :pointer, :string, :uint, :pointer, :pointer ], :int
    # attach_function :JS_ArgvCallee, [ :pointer ], :long

    # Array
    
    attach_function :JS_IsArrayObject, [ :pointer, :pointer ], :int
    attach_function :JS_GetArrayLength, [ :pointer, :pointer, :pointer ], :int
    attach_function :JS_SetArrayLength, [ :pointer, :pointer, :uint ], :int
    attach_function :JS_HasArrayLength, [ :pointer, :pointer, :pointer ], :int

    # Id

    attach_function :JS_DestroyIdArray, [ :pointer, :pointer ], :void

    # Stubs

    attach_function :JS_PropertyStub, [ :pointer, :pointer, :long, :pointer ], :int
    attach_function :JS_EnumerateStub, [ :pointer, :pointer ], :int
    attach_function :JS_ResolveStub, [ :pointer, :pointer, :long ], :int
    attach_function :JS_ConvertStub, [ :pointer, :pointer, :int, :pointer ], :int
    attach_function :JS_FinalizeStub, [ :pointer, :pointer ], :void

    # Version

    attach_function :JS_GetImplementationVersion, [  ], :string

    class JSClass < FFI::ManagedStruct
      layout(
             :name, :pointer,
             :flags, :uint,
             :addProperty, :JSPropertyOp,
             :delProperty, :JSPropertyOp,
             :getProperty, :JSPropertyOp,
             :setProperty, :JSPropertyOp,
             :enumerate, :JSEnumerateOp,
             :resolve, :JSResolveOp,
             :convert, :JSConvertOp,
             :finalize, :JSFinalizeOp,
             :getObjectOps, :JSGetObjectOps,
             :checkAccess, :JSCheckAccessOp,
             :call, :JSNative,
             :construct, :JSNative,
             :xdrObject, :JSXDRObjectOp,
             :hasInstance, :JSHasInstanceOp,
             :mark, :JSMarkOp,
             :reserveSlots, :JSReserveSlotsOp
             )

      def self.allocate 
        new(SpiderMonkey.calloc(1, self.size))
      end

      def self.release(ptr)
        SpiderMonkey.free(ptr)
      end

      def name=(str)
        @name = FFI::MemoryPointer.from_string(str)
        self[:name] = @name
      end
      def name
        @name.get_string(0)
      end
      def addProperty=(cb)
        @addProperty = cb
        self[:addProperty] = @addProperty
      end
      def addProperty
        @addProperty
      end
      def delProperty=(cb)
        @delProperty = cb
        self[:delProperty] = @delProperty
      end
      def delProperty
        @delProperty
      end
      def getProperty=(cb)
        @getProperty = cb
        self[:getProperty] = @getProperty
      end
      def getProperty
        @getProperty
      end
      def setProperty=(cb)
        @setProperty = cb
        self[:setProperty] = @setProperty
      end
      def setProperty
        @setProperty
      end
      def enumerate=(cb)
        @enumerate = cb
        self[:enumerate] = @enumerate
      end
      def enumerate
        @enumerate
      end
      def resolve=(cb)
        @resolve = cb
        self[:resolve] = @resolve
      end
      def resolve
        @resolve
      end
      def convert=(cb)
        @convert = cb
        self[:convert] = @convert
      end
      def convert
        @convert
      end
      def finalize=(cb)
        @finalize = cb
        self[:finalize] = @finalize
      end
      def finalize
        @finalize
      end
      def getObjectOps=(cb)
        @getObjectOps = cb
        self[:getObjectOps] = @getObjectOps
      end
      def getObjectOps
        @getObjectOps
      end
      def checkAccess=(cb)
        @checkAccess = cb
        self[:checkAccess] = @checkAccess
      end
      def checkAccess
        @checkAccess
      end
      def call=(cb)
        @call = cb
        self[:call] = @call
      end
      def call
        @call
      end
      def construct=(cb)
        @construct = cb
        self[:construct] = @construct
      end
      def construct
        @construct
      end
      def xdrObject=(cb)
        @xdrObject = cb
        self[:xdrObject] = @xdrObject
      end
      def xdrObject
        @xdrObject
      end
      def hasInstance=(cb)
        @hasInstance = cb
        self[:hasInstance] = @hasInstance
      end
      def hasInstance
        @hasInstance
      end
      def mark=(cb)
        @mark = cb
        self[:mark] = @mark
      end
      def mark
        @mark
      end
      def reserveSlots=(cb)
        @reserveSlots = cb
        self[:reserveSlots] = @reserveSlots
      end
      def reserveSlots
        @reserveSlots
      end

    end

    # FIXME: Hum ... revisit this solution please ...

    class JSClassWithNewResolve < JSClass
      layout(
             :name, :pointer,
             :flags, :uint,
             :addProperty, :JSPropertyOp,
             :delProperty, :JSPropertyOp,
             :getProperty, :JSPropertyOp,
             :setProperty, :JSPropertyOp,
             :enumerate, :JSEnumerateOp,
             :resolve, :JSNewResolveOp,
             :convert, :JSConvertOp,
             :finalize, :JSFinalizeOp,
             :getObjectOps, :JSGetObjectOps,
             :checkAccess, :JSCheckAccessOp,
             :call, :JSNative,
             :construct, :JSNative,
             :xdrObject, :JSXDRObjectOp,
             :hasInstance, :JSHasInstanceOp,
             :mark, :JSMarkOp,
             :reserveSlots, :JSReserveSlotsOp
             )

    end

    class JSIdArray < FFI::Struct
      layout(
             :length, :int,
             :vector, [:long, 1]
             )
    end


  end
end

module Johnson

  module SpiderMonkey
    class << self
      def JSVAL_CLRTAG(v)
        v & ~JSVAL_TAGMASK
      end
      def JSVAL_TO_GCTHING(v)
        JSVAL_CLRTAG(v)
      end
      def JSVAL_SETTAG(v, t)
        v | t
      end
      def JSVAL_TAG(v) 
        (v & JSVAL_TAGMASK)
      end
      def JSVAL_INT_POW2(n)
        1 << n
      end
      def JSVAL_TO_INT(v)         
        v >> 1
      end
      def INT_TO_JSVAL(i)
        ((i << 1) | JSVAL_INT)
      end
      def JSVAL_TO_OBJECT(v)
        JSVAL_TO_GCTHING(v)
      end
      def OBJECT_TO_JSVAL(obj)
        FFI::MemoryPointer.new(:pointer).write_pointer(obj).read_long
      end
      def BOOLEAN_TO_JSVAL(b)
        JSVAL_SETTAG(b << JSVAL_TAGBITS, JSVAL_BOOLEAN)
      end
      def JSVAL_IS_STRING(v)      
        JSVAL_TAG(v) == JSVAL_STRING
      end
      def JSVAL_IS_INT(v)
        (v & JSVAL_INT != 0) && (v != JSVAL_VOID)
      end
      def JSVAL_IS_OBJECT(v)      
        JSVAL_TAG(v) == JSVAL_OBJECT
      end
      def JS_BIT(n)
        1 << n
      end
      def JS_BITMASK(n)
        JS_BIT(n) -1
      end
      def JSCLASS_HAS_RESERVED_SLOTS(n)   
        (((n) & JSCLASS_RESERVED_SLOTS_MASK) << JSCLASS_RESERVED_SLOTS_SHIFT)
      end
    end

  end

end

# Constants

module Johnson
  module SpiderMonkey

    JS_TRUE = 1
    JS_FALSE = 0

    JSTYPE_VOID = 0
    JSTYPE_OBJECT = 1
    JSTYPE_FUNCTION = 2
    JSTYPE_STRING = 3
    JSTYPE_NUMBER = 4
    JSTYPE_BOOLEAN = 5
    JSTYPE_NULL = 6
    JSTYPE_XML = 7
    JSTYPE_LIMIT = 8

    JSVERSION_UNKNOWN = -1
    JSVERSION_DEFAULT = 0
    JSVERSION_1_0 = 100
    JSVERSION_1_1 = 110
    JSVERSION_1_2 = 120
    JSVERSION_1_3 = 130
    JSVERSION_1_4 = 140
    JSVERSION_ECMA_3 = 148
    JSVERSION_1_5 = 150
    JSVERSION_1_6 = 160
    JSVERSION_1_7 = 170
    JSVERSION_1_8 = 180
    JSVERSION_LATEST = JSVERSION_1_8

    JSVAL_OBJECT = 0x0
    JSVAL_INT = 0x1
    JSVAL_DOUBLE = 0x2
    JSVAL_STRING = 0x4
    JSVAL_BOOLEAN = 0x6
    JSVAL_TAGBITS = 3
    JSVAL_INT_BITS = 31
    JSPROP_ENUMERATE = 0x01
    JSPROP_READONLY = 0x02
    JSPROP_PERMANENT = 0x04
    JSPROP_EXPORTED = 0x08
    JSPROP_GETTER = 0x10
    JSPROP_SETTER = 0x20
    JSPROP_SHARED = 0x40
    JSPROP_INDEX = 0x80
    JSFUN_LAMBDA = 0x08
    JSFUN_GETTER = 0x10
    JSFUN_SETTER = 0x20
    JSFUN_BOUND_METHOD = 0x40
    JSFUN_HEAVYWEIGHT = 0x80
    JSFUN_THISP_STRING = 0x0100
    JSFUN_THISP_NUMBER = 0x0200
    JSFUN_THISP_BOOLEAN = 0x0400
    JSFUN_THISP_PRIMITIVE = 0x0700
    JSFUN_FAST_NATIVE = 0x0800
    JSFUN_FLAGS_MASK = 0x0ff8
    JSFUN_STUB_GSOPS = 0x1000
    JSFUN_GENERIC_NATIVE = 0x08

    JSRESOLVE_QUALIFIED = 0x01
    JSRESOLVE_ASSIGNING = 0x02
    JSRESOLVE_DETECTING = 0x04
    JSRESOLVE_DECLARING = 0x08
    JSRESOLVE_CLASSNAME = 0x10

    JSCLASS_HAS_PRIVATE = (1 << 0)
    JSCLASS_NEW_ENUMERATE = (1 << 1)
    JSCLASS_NEW_RESOLVE = (1 << 2)
    JSCLASS_PRIVATE_IS_NSISUPPORTS = (1 << 3)
    JSCLASS_SHARE_ALL_PROPERTIES = (1 << 4)
    JSCLASS_NEW_RESOLVE_GETS_START = (1 << 5)
    JSCLASS_CONSTRUCT_PROTOTYPE = (1 << 6)
    JSCLASS_DOCUMENT_OBSERVER = (1 << 7)
    JSCLASS_RESERVED_SLOTS_SHIFT = 8
    JSCLASS_RESERVED_SLOTS_WIDTH = 8
    JSCLASS_HIGH_FLAGS_SHIFT = (8+8)
    JSCLASS_IS_EXTENDED = (1 << ((8+8) +0))
    JSCLASS_IS_ANONYMOUS = (1 << ((8+8) +1))
    JSCLASS_IS_GLOBAL = (1 << ((8+8) +2))
    JSCLASS_MARK_IS_TRACE = (1 << ((8+8) +3))
    JSCLASS_CACHED_PROTO_SHIFT = ((8+8) +8)
    JSCLASS_CACHED_PROTO_WIDTH = 8

    JSVAL_VOID = INT_TO_JSVAL(0 - JSVAL_INT_POW2(30))
    JSVAL_NULL = OBJECT_TO_JSVAL(nil)
    JSVAL_ZERO = INT_TO_JSVAL(0)
    JSVAL_ONE = INT_TO_JSVAL(1)
    JSVAL_FALSE = BOOLEAN_TO_JSVAL(JS_FALSE)
    JSVAL_TRUE = BOOLEAN_TO_JSVAL(JS_TRUE)

    JSOPTION_VAROBJFIX = JS_BIT(2)
    JSOPTION_DONT_REPORT_UNCAUGHT = JS_BIT(8)

    JSVAL_TAGMASK = JS_BITMASK(JSVAL_TAGBITS)
    JSCLASS_RESERVED_SLOTS_MASK = JS_BITMASK(JSCLASS_RESERVED_SLOTS_WIDTH)
    JSCLASS_GLOBAL_FLAGS = (JSCLASS_IS_GLOBAL | JSCLASS_HAS_RESERVED_SLOTS(33))


  end
end

module Johnson

  module SpiderMonkey
    VERSION = SpiderMonkey.JS_GetImplementationVersion
  end

end

