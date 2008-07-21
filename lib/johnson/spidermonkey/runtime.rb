module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Runtime # native
      CONTEXT_MAP_KEY = :johnson_context_map

      def initialize(options={})
        @debugger = nil
        @compiled_scripts = {}
        @gcthings = {}
        initialize_native(options)
        self["Ruby"] = Object
      end
      
      # called from js_land_proxy.c:make_js_land_proxy
      def add_gcthing(thing)
        @gcthings[thing.object_id] = thing
      end
      
      # called from js_land_proxy.c:finalize
      def remove_gcthing(object_id)
        @gcthings.delete(object_id) if @gcthings
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

      ###
      # Evaluate +script+ with +filename+ and +linenum+
      def evaluate(script, filename = nil, linenum = nil)
        compiled_script = compile(script, filename, linenum)
        evaluate_compiled_script(compiled_script)
      end

      ###
      # Compile +script+ with +filename+ and +linenum+
      def compile(script, filename=nil, linenum=nil)
        filename ||= 'none'
        linenum  ||= 1
        @compiled_scripts[filename] = native_compile(script, filename, linenum)
      end

      ###
      # Yield to +block+ in +filename+ at +linenum+
      def break(filename, linenum, &block)
        raise "#{filename} has not been compiled" unless @compiled_scripts.key?(filename)

        compiled_script = @compiled_scripts[filename]
        set_trap(compiled_script, linenum, block)
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
