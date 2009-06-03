module Johnson
  module SpiderMonkey

    module Convert

      class << self

        def convert_to_ruby(runtime, js_value)
          
          context = runtime.context
          
          js_value.root
          value = js_value.value

          if value == JSVAL_NULL
            js_value.unroot
            return nil
          end

          case SpiderMonkey.JS_TypeOfValue(context, value)
            
          when SpiderMonkey::JSTYPE_VOID
            js_value.unroot
            return nil

          when SpiderMonkey::JSTYPE_BOOLEAN
            js_value.unroot
            return value == SpiderMonkey::JSVAL_TRUE ? true : false

          when SpiderMonkey::JSTYPE_STRING
            js_value.unroot
            return to_ruby_string(runtime, value)
            
          when SpiderMonkey::JSTYPE_NUMBER
            if SpiderMonkey.JSVAL_IS_INT(value)
              js_value.unroot
              return to_ruby_fixnum_or_bignum(runtime, value)
            else
              js_value.unroot
              return to_ruby_float(runtime, value)
            end

          when SpiderMonkey::JSTYPE_OBJECT, SpiderMonkey::JSTYPE_FUNCTION

            if SpiderMonkey.OBJECT_TO_JSVAL(runtime.native_global) == value
              js_value.unroot
              return SpiderMonkey::RubyLandProxy.make(runtime, value, 'GlobalProxy')
            end  

            # this conditional requires the Prelude
            if js_value_is_symbol?(runtime, value)
              js_value.unroot
              return SpiderMonkey.JS_GetStringBytes(SpiderMonkey.JS_ValueToString(runtime.context, value)).to_sym
            end

            if JSLandProxy.js_value_is_proxy?(js_value)
              js_value.unroot
              return JSLandProxy.unwrap_js_land_proxy(runtime, js_value)
            end

            if js_value_is_regexp?(runtime, value)
              js_value.unroot
              return convert_regexp_to_ruby(runtime, value)
            end

            js_value.unroot
            return SpiderMonkey::RubyLandProxy.make(runtime, value, 'RubyLandProxy')

          end      

        end

        alias_method :to_ruby, :convert_to_ruby

        def convert_to_js(runtime, value)
          
          case value

          when NilClass
            SpiderMonkey::JSValue.new(runtime, JSVAL_NULL)

          when TrueClass
            SpiderMonkey::JSValue.new(runtime, JSVAL_TRUE)

          when FalseClass
            SpiderMonkey::JSValue.new(runtime, JSVAL_FALSE)

          when String
            SpiderMonkey::JSValue.new(runtime, convert_ruby_string_to_js(runtime, value))

          when Fixnum
            SpiderMonkey::JSValue.new(runtime, SpiderMonkey.INT_TO_JSVAL(value))

          when Float, Bignum
            SpiderMonkey::JSValue.new(runtime, convert_float_or_bignum_to_js(runtime, value))

          when Symbol
            SpiderMonkey::JSValue.new(runtime, convert_symbol_to_js(runtime, value))

          when Regexp
            SpiderMonkey::JSValue.new(runtime, convert_regexp_to_js(runtime, value))

          when Class, Hash, Module, File, Struct, Object, Array
            if value.kind_of?(SpiderMonkey::RubyLandProxy)
              value.proxy_js_value
            else
              SpiderMonkey::JSLandProxy.make(runtime, value)
            end
          else
            raise 'Unknown ruby type in switch'
          end

        end

        alias_method :to_js, :convert_to_js

        private

        def convert_ruby_string_to_js(runtime, value)
          js_string = SpiderMonkey.JS_NewStringCopyN(runtime.context, value, value.size)
          SpiderMonkey.STRING_TO_JSVAL(js_string)
        end

        def convert_float_or_bignum_to_js(runtime, value)
          retval = FFI::MemoryPointer.new(:long)
          SpiderMonkey.JS_NewNumberValue(runtime.context, value.to_f, retval)
          retval
        end

        def convert_regexp_to_js(runtime, value)
          SpiderMonkey.OBJECT_TO_JSVAL(SpiderMonkey.JS_NewRegExpObject(runtime.context, value.source, value.source.size, value.options))
        end

        def convert_symbol_to_js(runtime, value)
          to_s = value.to_s
          johnson = FFI::MemoryPointer.new(:long)
          retval = FFI::MemoryPointer.new(:long)

          name_value = JSValue.new(runtime, SpiderMonkey.STRING_TO_JSVAL(SpiderMonkey.JS_NewStringCopyN(runtime.context, to_s, to_s.size)))
          name_value.root(binding)
          SpiderMonkey.JS_GetProperty(runtime.context, runtime.native_global, "Johnson", johnson)
          johnson_value = JSValue.new(runtime, johnson).root(binding)
          SpiderMonkey.JS_CallFunctionName(runtime.context, johnson_value.to_object, "symbolize", 1, name_value, retval)

          name_value.unroot
          johnson_value.unroot

          retval
        end

        def to_ruby_fixnum_or_bignum(runtime, value)
          SpiderMonkey.JSVAL_TO_INT(value)
        end

        def to_ruby_float(runtime, value)
          rvalue = FFI::MemoryPointer.new(:double)
          SpiderMonkey.JS_ValueToNumber(runtime.context, value, rvalue)
          rvalue.get_double(0)
        end

        def to_ruby_string(runtime, value)
          js_string = JSGCThing.new(runtime, SpiderMonkey.JSVAL_TO_STRING(value))
          js_string.root(binding)
          result = SpiderMonkey.JS_GetStringBytes(js_string)
          js_string.unroot
          result
        end
        
        def convert_regexp_to_ruby(runtime, value)
          JSValue.new(runtime, value).root(binding) do |js_value|
            re = SpiderMonkey::JSRegExp.new(SpiderMonkey.JS_GetPrivate(runtime.context, js_value.to_object))
            Regexp.new(to_ruby_string(runtime, re[:source].address), re[:flags])
          end
        end

        def js_value_is_regexp?(runtime, value)
          JSValue.new(runtime, value).root(binding) do |js_value|
            hack = "hack"
            regexp_js_class = SpiderMonkey.JS_GetClass(SpiderMonkey.JS_NewRegExpObject(runtime.context, hack, hack.size, 0))
            SpiderMonkey.JS_InstanceOf(runtime.context, js_value.to_object, regexp_js_class, nil) == JS_TRUE ? true : false
          end
        end

        def js_value_is_symbol?(runtime, maybe_symbol)
          context = runtime.context

          johnson = FFI::MemoryPointer.new(:long)
          symbol = FFI::MemoryPointer.new(:long)
          is_a_symbol = FFI::MemoryPointer.new(:int)

          maybe_symbol_value = JSValue.new(runtime, maybe_symbol).root(binding)
          SpiderMonkey.JS_GetProperty(context, runtime.native_global, 'Johnson', johnson)

          raise "Unable to retrieve Johnson from JSLand" unless SpiderMonkey.JSVAL_IS_OBJECT(johnson.read_long)

          johnson_value = JSValue.new(runtime, johnson).root(binding)

          SpiderMonkey.JS_GetProperty(context, johnson_value.to_object, "Symbol", symbol)
          raise "Unable to retrieve Johnson.Symbol from JSLand" unless SpiderMonkey.JSVAL_IS_OBJECT(symbol.read_long)

          symbol_value = JSValue.new(runtime, symbol).root(binding)
          
          SpiderMonkey.JS_HasInstance(context, symbol_value.to_object, maybe_symbol, is_a_symbol)

          maybe_symbol_value.unroot
          johnson_value.unroot
          symbol_value.unroot

          is_a_symbol.read_long != JS_FALSE

        end

      end
    end
  end
end
