module Johnson
  module SpiderMonkey

    at_exit do
      runtimes.each { |rt| rt.destroy }
      SpiderMonkey.JS_ShutDown
    end

    def self.runtimes
      @runtimes ||= []
    end

    class Runtime

      CONTEXT_MAP_KEY = :johnson_context_map

      attr_reader :global, :gc_zeal

      include HasPointer

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

      def initialize

        @ptr = SpiderMonkey.JS_NewRuntime(0x100000)
        @global = SpiderMonkey.JS_GetGlobalObject(context)
        @gc_zeal = 0

        SpiderMonkey.runtimes << self
        
      end

      def destroy
        contexts = (Thread.current[CONTEXT_MAP_KEY] ||= {})
        cx = contexts[self.object_id]

        RubyLandProxy.finalize_proxy_in_roots

        SpiderMonkey.JS_DestroyContext(cx)
        SpiderMonkey.JS_DestroyRuntime(self)
      end

      def gc_zeal=(value)
        SpiderMonkey.JS_SetGCZeal(context, value)
      end

      def context
        contexts = (Thread.current[CONTEXT_MAP_KEY] ||= {})
        contexts[self.object_id] ||= Context.new(self)
      end

      def has_global?
        not (@global.nil? or global.null?)
      end
      
      def [](key)
        JSValue.new(context, SpiderMonkey.OBJECT_TO_JSVAL(@global)).to_ruby[key]
      end
      
      def []=(key, value)
        JSValue.new(context, SpiderMonkey.OBJECT_TO_JSVAL(@global)).to_ruby[key] = value
      end

      def evaluate(script, filename = nil, linenum = nil)
        compile_and_evaluate(script, filename, linenum)
      end

      def evaluate_and_return_jsval(script, filename = nil, linenum = nil)

        filename ||= 'none'
        linenum  ||= 1
        rval = FFI::MemoryPointer.new(:long)
        ok = SpiderMonkey.JS_EvaluateScript(context, global, script, script.size, filename, linenum, rval)

        if ok == JS_FALSE

          if SpiderMonkey.JS_IsExceptionPending(context) == JS_TRUE
            SpiderMonkey.JS_GetPendingException(context, context.exception);
            SpiderMonkey.JS_ClearPendingException(context)
          end

          if context.has_exception?
            self.class.raise_js_exception(convert_to_ruby(context.exception.read_long))
          end
          
        end

        rval

      end

      private

      def compile_and_evaluate(script, filename, linenum)

        filename ||= 'none'
        linenum  ||= 1

        rval = FFI::MemoryPointer.new(:long)
        ok = SpiderMonkey.JS_EvaluateScript(context, global, script, script.size, filename, linenum, rval)

        if ok == JS_FALSE

          if SpiderMonkey.JS_IsExceptionPending(context) == JS_TRUE
            SpiderMonkey.JS_GetPendingException(context, context.exception);
            SpiderMonkey.JS_ClearPendingException(context)
          end

          if context.has_exception?
            self.class.raise_js_exception(convert_to_ruby(context.exception.read_long))
          end
          
        end

        JSValue.new(context, rval).to_ruby # convert_to_ruby(rval.read_long)
      end

    end
  end
end
