require 'dl/struct'

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

      def new_script_hook
        logger.debug("new_script_hook")
      end

      def destroy_script_hook
        logger.debug("destroy_script_hook")
      end

      def debugger_handler
        logger.debug("debugger_handler")
      end

      def source_handler(filename, line_number)
        logger.debug("source_handler: #{filename}(#{line_number})")
      end

      def execute_hook(before)
        logger.debug("execute_hook: #{before}")
      end

      def call_hook(before)
        logger.debug("call_hook: #{before}")
      end

      def object_hook
        logger.debug("object_hook")
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
