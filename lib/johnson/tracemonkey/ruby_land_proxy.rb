module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class RubyLandProxy < Johnson::RubyLandProxy # native
      module Callable
        def call_using(this, *args)
          native_call(this, *args)
        end
      end
    end
    class RubyLandScript < Johnson::SpiderMonkey::RubyLandProxy # native
      def break(linenum, &block)
        runtime.set_trap(self, linenum, block)
        runtime.traps << [self, linenum]
      end
    end
  end
end
