module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Debugger # native
      # Enum constants from jsprvtd.h
      JSTRAP_ERROR    = 0
      JSTRAP_CONTINUE = 1
      JSTRAP_RETURN   = 2
      JSTRAP_THROW    = 3
      JSTRAP_LIMIT    = 4

      attr_accessor :logger
      def initialize(logger)
        @logger = logger
      end

      def interrupt_handler(context)
        logger.debug("interrupt_handler")
      end

      def new_script_hook(context)
        logger.debug("new_script_hook")
      end

      def destroy_script_hook(context)
        logger.debug("destroy_script_hook")
      end

      def debugger_handler(context)
        logger.debug("debugger_handler")
      end

      def source_handler
        logger.debug("source_handler")
      end

      def execute_hook(context)
        logger.debug("execute_hook")
      end

      def call_hook(context)
        logger.debug("call_hook")
      end

      def object_hook
        logger.debug("object_hook")
      end

      def throw_hook(context)
        logger.debug("throw_hook")
      end

      def debug_error_hook(context)
        logger.debug("debug_error_hook")
      end
    end
  end
end
