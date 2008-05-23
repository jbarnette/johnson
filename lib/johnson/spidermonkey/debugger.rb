module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Debugger # native
      attr_accessor :logger
      def initialize(logger)
        @logger = logger
      end

      def interrupt_handler
        logger.debug("interrupt_handler")
      end

      def new_script_hook(filename, linenum)
        logger.debug("new_script_hook: #{filename} #{linenum}")
      end

      def destroy_script_hook
        logger.debug("destroy_script_hook")
      end

      def debugger_handler
        logger.debug("debugger_handler")
      end

      def source_handler(filename, line_number, str)
        logger.debug("source_handler: #{filename}(#{line_number}): #{str}")
      end

      # +call_hook+ is called before and after script execution.  +before+
      # is +true+ if before, +false+ otherwise.
      def execute_hook(before, ok)
        logger.debug("execute_hook: #{before} #{ok}")
      end

      # +call_hook+ is called before and after a function call.  +before+
      # is +true+ if before, +false+ otherwise.
      def call_hook(before, ok)
        logger.debug("call_hook: #{before} #{ok}")
      end

      def object_hook(object, is_new)
        # FIXME object.to_s breaks for eval... wtf?
        logger.debug("object_hook: #{object.class} #{is_new}")
      end

      def throw_hook
        logger.debug("throw_hook")
      end

      def debug_error_hook(message)
        logger.debug("debug_error_hook: #{message}")
      end
    end
  end
end
