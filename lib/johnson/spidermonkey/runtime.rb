module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Runtime # native
      def initialize(options={})
        initialize_native(options)
        self["Ruby"] = Object
      end

      def current_context
        contexts = (Thread.current[:johson_context_map] ||= {})
        contexts[self.object_id] ||= Context.new(self)
      end

      def [](key)
        global[key]
      end
      
      def []=(key, value)
        global[key] = value
      end

      protected
      
      def handle_js_exception(jsex)
        raise jsex if Exception === jsex
        raise Johnson::Error.new(jsex.to_s) unless Johnson::SpiderMonkey::RubyLandProxy === jsex
        
        # FIXME: sanitize stack traces
        stack = jsex.stack rescue nil
        
        ex = Johnson::Error.new(jsex)
        if stack
          ex.set_backtrace(stack.split("\n") + caller)
        else
          ex.set_backtrace(caller)
        end
        
        raise ex
      end
    end
  end
end
