module Johnson
  module SpiderMonkey

    class RubyValue

      def initialize(context, value)
        @context, @value = context, value
      end

      def to_js
        
        case @value

        when NilClass
          SpiderMonkey::JSValue.new(@context, JSVAL_NULL)

        when TrueClass
          SpiderMonkey::JSValue.new(@context, JSVAL_TRUE)

        when FalseClass
          SpiderMonkey::JSValue.new(@context, JSVAL_FALSE)

        when String
          SpiderMonkey::JSValue.new(@context, convert_ruby_string_to_js)

        when Fixnum
          SpiderMonkey::JSValue.new(@context, SpiderMonkey.INT_TO_JSVAL(@value))

        when Float, Bignum
          SpiderMonkey::JSValue.new(@context, convert_float_or_bignum_to_js)

        when Class, Hash, Module, File, Struct, Object, Array
          if @value.kind_of?(SpiderMonkey::RubyLandProxy)
            @value.js_value
          else
            SpiderMonkey::JSValue.new(@context, SpiderMonkey::JSLandProxy.make(@value))
          end
        else
          raise 'Unknown ruby type in switch'
        end

      end

      private

      def convert_ruby_string_to_js
        js_string = SpiderMonkey.JS_NewStringCopyN(@context, @value, @value.size)
        SpiderMonkey.STRING_TO_JSVAL(js_string)
      end

      def convert_float_or_bignum_to_js
        retval = FFI::MemoryPointer.new(:long)
        SpiderMonkey.JS_NewNumberValue(@context, @value.to_f, retval)
        retval
      end

    end
  end
end

module Johnson
  module SpiderMonkey

    class JSValue < JSGCThing

      attr_reader :value, :context

      def initialize(context, pointer_or_value)

        @context = context

        if pointer_or_value.kind_of?(FFI::Pointer)
          @value = pointer_or_value.read_long
          @ptr = @ptr_to_be_rooted = pointer_or_value
        elsif pointer_or_value.kind_of?(Fixnum) or pointer_or_value.kind_of?(Bignum)
          @value = pointer_or_value
          @ptr = @ptr_to_be_rooted = FFI::MemoryPointer.new(:long).write_long(@value)
        else
          raise "Invalid initialization value for SpiderMonkey::JSValue"
        end

      end

      def to_object
        js_object = FFI::MemoryPointer.new(:pointer)
        SpiderMonkey.JS_ValueToObject(@context, @value, js_object)
        js_object.read_pointer
      end

      def to_ruby

        if @value == JSVAL_NULL
          unroot
          return nil
        end

        case SpiderMonkey.JS_TypeOfValue(@context, @value)
          
        when SpiderMonkey::JSTYPE_VOID
          unroot
          return nil

        when SpiderMonkey::JSTYPE_BOOLEAN
          unroot
          return @value == SpiderMonkey::JSVAL_TRUE ? true : false

        when SpiderMonkey::JSTYPE_STRING
          unroot
          return to_ruby_string
          
        when SpiderMonkey::JSTYPE_NUMBER
          if SpiderMonkey.JSVAL_IS_INT(@value)
            unroot
            return to_ruby_fixnum_or_bignum
          else
            unroot
            return to_ruby_float
          end

        when SpiderMonkey::JSTYPE_OBJECT, SpiderMonkey::JSTYPE_FUNCTION

          if SpiderMonkey.OBJECT_TO_JSVAL(@context.runtime.native_global) == @value
            unroot
            return SpiderMonkey::RubyLandProxy.make(@context, @value, 'GlobalProxy')
          end  

          # if RubyLandProxy.has_proxy?(@context.runtime, self)
          #   unroot
          #   return RubyLandProxy.unwrap_js_land_proxy(@context.runtime, self)
          # end
          
          unroot
          return SpiderMonkey::RubyLandProxy.make(@context, @value, 'RubyLandProxy')

        end      

      end
      
      private

      def to_ruby_fixnum_or_bignum
        SpiderMonkey.JSVAL_TO_INT(@value)
      end

      def to_ruby_float
        rvalue = FFI::MemoryPointer.new(:double)
        SpiderMonkey.JS_ValueToNumber(@context, @value, rvalue)
        rvalue.get_double(0)
      end

      def to_ruby_string
        js_string = JSGCThing.new(@context, SpiderMonkey.JSVAL_TO_STRING(@value))
        js_string.root(binding)
        result = SpiderMonkey.JS_GetStringBytes(js_string)
        js_string.unroot
        result
      end

    end
  end
end
