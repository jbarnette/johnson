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

      attr_reader :native_global, :gc_zeal
      attr_reader :roots, :jsids, :rbids
      private :roots, :jsids, :rbids
      
      include HasPointer

      class << self
        
        def finalize(id)
          SpiderMonkey.runtimes[id]
        end

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
        @native_global = SpiderMonkey.JS_GetGlobalObject(context)
        @gc_zeal = 0

        @jsids = {}
        @rbids = {}
        @roots = []

        SpiderMonkey.runtimes << self
      end

      def destroy
        @roots.each { |js_value| js_value.unroot_rt }
        @roots.clear
        @jsids.clear

        destroy_contexts
        SpiderMonkey.JS_DestroyRuntime(self)
      end

      def gc_zeal=(value)
        SpiderMonkey.JS_SetGCZeal(context, value)
      end

      def context
        contexts = (Thread.current[CONTEXT_MAP_KEY] ||= {})
        contexts[self.object_id] ||= Context.new(self)
      end

      def has_native_global?
        false unless defined?(@native_global) && !native_global.null?
      end
      
      def [](key)
        global[key]
      end
      
      def []=(key, value)
        global[key] = value
      end

      def global
        JSValue.new(self, SpiderMonkey.OBJECT_TO_JSVAL(@native_global)).to_ruby
      end

      def evaluate(script, filename = nil, linenum = nil)
        compile_and_evaluate(script, filename, linenum)
      end

      private

      def destroy_contexts
        iterator = FFI::MemoryPointer.new(:pointer).write_pointer(FFI::Pointer::NULL)

        while !(SpiderMonkey.JS_ContextIterator(self, iterator)).null?
          SpiderMonkey.JS_DestroyContext(iterator.read_pointer)
          iterator = FFI::MemoryPointer.new(:pointer).write_pointer(FFI::Pointer::NULL)
        end
      end

      def compile_and_evaluate(script, filename, linenum)

        unless filename
          @current_filename = FFI::MemoryPointer.from_string('none')
        else
          @current_filename = FFI::MemoryPointer.from_string(filename)
        end

        @linenum = linenum || 1

        @current_script = FFI::MemoryPointer.from_string(script)
        @current_script_size = script.size
        @retval = FFI::MemoryPointer.new(:long)

        ok = SpiderMonkey.JS_EvaluateScript(context,
                                            native_global, 
                                            @current_script, 
                                            @current_script_size,
                                            @current_filename,
                                            @linenum, @retval)

        if ok == JS_FALSE

          if SpiderMonkey.JS_IsExceptionPending(context) == JS_TRUE
            SpiderMonkey.JS_GetPendingException(context, context.exception);
            SpiderMonkey.JS_ClearPendingException(context)
          end

          if context.has_exception?
            raise "Some error occoured."
#            self.class.raise_js_exception(convert_to_ruby(context.exception.read_long))
          end
          
        end

        JSValue.new(self, @retval).to_ruby
      end

    end
  end
end
