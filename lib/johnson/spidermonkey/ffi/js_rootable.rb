module Johnson
  module SpiderMonkey

    class JSRootable
      include HasPointer

      def initialize(context, value)
        @context, @value = context, value
        @ptr_to_be_rooted = FFI::MemoryPointer.new(:pointer).write_pointer(value)
        @ptr = value
      end
      def root_rt(bind = nil, name = '')
        SpiderMonkey.JS_AddNamedRootRT(@context.runtime, @ptr_to_be_rooted, format_root_string(bind, name))
      end

      def unroot_rt
        SpiderMonkey.JS_RemoveRootRT(@context.runtime, @ptr_to_be_rooted)
      end

      def root(bind = nil, name = '')
        SpiderMonkey.JS_AddNamedRoot(@context, @ptr_to_be_rooted, format_root_string(bind, name))
      end

      def unroot
        SpiderMonkey.JS_RemoveRoot(@context, @ptr_to_be_rooted)
      end

      private

      def format_root_string(bind, name)
        format_name = name.empty? ? @value.inspect : name
        format_binding = bind if bind
        unless format_binding
          format_name
        else
          sprintf("%s[%d]:%s: %s", 
                  format_file(format_binding), 
                  format_line(format_binding), 
                  format_method(format_binding), 
                  format_name)
        end
      end

      def format_file(bind)
        eval('__FILE__', bind)
      end

      def format_line(bind)
        eval('__LINE__', bind)
      end

      def format_method(bind)
        begin
          eval('__method__', bind)
        rescue NameError
          warn 'WARNING: You should pass --1.9 option to jruby in order to use Kernel#__method__'
          'nomethod'
        end
      end

    end

  end
end

