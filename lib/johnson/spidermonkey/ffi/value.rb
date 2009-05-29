module Johnson
  module SpiderMonkey

    class RubyValue

      include Convert

      def initialize(runtime, value)
        @runtime = runtime
        @context = runtime.context
        @value = value
      end

      def to_js
        convert_to_js(@value)
      end

    end
  end
end

module Johnson
  module SpiderMonkey

    class JSValue < JSGCThing

      include Convert

      attr_reader :value, :context

      def initialize(runtime, pointer_or_value)
        
        @runtime = runtime
        @context = runtime.context

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
        SpiderMonkey.JSVAL_TO_OBJECT(@value)
      end

      def to_ruby
        convert_to_ruby(self)
      end


    end
  end
end
