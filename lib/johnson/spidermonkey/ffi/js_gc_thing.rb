module Johnson
  module SpiderMonkey

    class JSGCThing
      class << self
        def root_names
          @root_names ||= {}
        end
      end

      include HasPointer

      def initialize(runtime, value)
        @runtime = runtime
        @context = runtime.context
        @value = value
        @ptr_to_be_rooted = FFI::MemoryPointer.new(:pointer).write_pointer(value)
        @ptr = value
        @rooted = false
      end

      def root_rt(bind = nil, name = '')
        if add_root_rt(bind, name)
          @rooted = true
          retval = self
        end
        if block_given?
          retval = yield self
          unroot
        end
        retval
      end

      def unroot_rt
        remove_root_rt
        @rooted = false
        self
      end

      def root(bind = nil, name = '', &blk)
        if add_root(bind, name)
          @rooted = true
          retval = self
        end
        if block_given?
          retval = yield self
          unroot
        end
        retval
      end

      def unroot
        remove_root
        @rooted = false
        self
      end

      def rooted?
        @rooted == true
      end

      def unrooted?
        not rooted?
      end

      private

      def add_name(name)
        self.class.root_names[@ptr_to_be_rooted] = FFI::MemoryPointer.from_string(name)
      end

      def remove_name
        self.class.root_names.delete(@ptr_to_be_rooted)
      end

      def add_root(bind, name)
        add_name(name)
        SpiderMonkey.JS_AddNamedRoot(@context, @ptr_to_be_rooted, format_root_string(bind, name))
      end

      def add_root_rt(bind, name)
        add_name(name)
        SpiderMonkey.JS_AddNamedRootRT(@context.runtime, @ptr_to_be_rooted, format_root_string(bind, name))
      end

      def remove_root
        remove_name
        SpiderMonkey.JS_RemoveRoot(@context, @ptr_to_be_rooted)
      end

      def remove_root_rt
        remove_name
        SpiderMonkey.JS_RemoveRootRT(@context.runtime, @ptr_to_be_rooted)
      end

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
        unless RUBY_PLATFORM =~ /java/
          eval('__method__', bind)
        else
          RUBY_VERSION =~ /1\.9/ ? eval('__method__', bind) : '[cannotresolvemethod]'
        end
      end

    end

  end
end

