module Johnson #:nodoc:
  module TraceMonkey #:nodoc:
    class Runtime < Johnson::Runtime # native
      def version
        TraceMonkey::VERSION
      end

      CONTEXT_MAP_KEY = :johnson_context_map

      attr_reader :traps
      def initialize(options={})
        @debugger = nil
        @gcthings = {}
        @traps = []
        initialize_native(options)
        super()
      end
      
      # called from js_land_proxy.c:make_js_land_proxy
      def add_gcthing(thing)
        @gcthings[thing.object_id] = thing
      end
      
      # called from js_land_proxy.c:finalize
      def remove_gcthing(object_id)
        @gcthings.delete(object_id) if defined? @gcthings
      end

      def debugger?
        not @debugger.nil?
      end

      def current_context
        contexts = (Thread.current[CONTEXT_MAP_KEY] ||= {})
        contexts[self.object_id] ||= Context.new(self)
      end

      def evaluate(script, filename = nil, linenum = nil, global=nil, scope=nil)
        return nil if script.nil?
        compiled_script = compile(script, filename, linenum, global)
        evaluate_compiled_script(compiled_script, scope)
      end

      alias :evaluate_compiled_script_without_clearing_traps :evaluate_compiled_script
      def evaluate_compiled_script script, scope=nil
        evaluate_compiled_script_without_clearing_traps(script,scope)
      ensure
        @traps.each do |trap_tuple|
          clear_trap(*trap_tuple)
        end
      end

      ###
      # Compile +script+ with +filename+ and +linenum+
      def compile(script, filename=nil, linenum=nil, global=nil)
        filename ||= 'none'
        linenum  ||= 1
        native_compile(script, filename, linenum, global)
      end

      class << self

        def parse_io *args
          Johnson::TraceMonkey::ImmutableNode.parse_io( *args )
        end

        def raise_js_exception(jsex)
          raise jsex if Exception === jsex
          raise Johnson::Error.new(jsex.to_s) unless Johnson::TraceMonkey::RubyLandProxy === jsex

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
      # Called by TraceMonkey's garbage collector to determine whether or
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
