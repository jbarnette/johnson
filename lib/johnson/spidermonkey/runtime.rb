module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Runtime # native
      CONTEXT_MAP_KEY = :johnson_context_map

      def initialize(options={})
        initialize_native(options)
        self["Ruby"] = Object
      end

      def current_context
        contexts = (Thread.current[CONTEXT_MAP_KEY] ||= {})
        contexts[self.object_id] ||= Context.new(self)
      end

      def [](key)
        global[key]
      end
      
      def []=(key, value)
        global[key] = value
      end

      class << self
        def raise_js_exception(jsex)
          raise jsex if Exception === jsex
          raise Johnson::Error.new(jsex.to_s) unless Johnson::SpiderMonkey::RubyLandProxy === jsex

          stack = jsex.stack rescue nil

          message = jsex['message'] || jsex.to_s
          at = "(#{jsex['fileName']}):#{jsex['lineNumber']}"
          ex = Johnson::Error.new("#{message} at #{at}")
          if stack
            js_caller = stack.split("\n").find_all { |x| x != '@:0' }
            ex.set_backtrace(js_caller + caller)
          else
            ex.set_backtrace(caller)
          end

          raise ex
        end
      end

      private
      # Called by SpiderMonkey's garbage collector to determine whether or
      # not it should GC
      def should_sm_gc?
        return false if Thread.list.find_all { |t|
          t.key?(CONTEXT_MAP_KEY)
        }.length > 1
        true
      end
    end
  end
end
