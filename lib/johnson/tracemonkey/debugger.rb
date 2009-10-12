module Johnson #:nodoc:
  module TraceMonkey #:nodoc:
    class Debugger # native
      JSTRAP_ERROR    = 0
      JSTRAP_CONTINUE = 1
      JSTRAP_RETURN   = 2
      JSTRAP_THROW    = 3
      JSTRAP_LIMIT    = 4
      attr_accessor :logger
      def initialize(logger)
        @logger = logger
      end

      def interrupt_handler(context, script, bytecode)
        line_num  = line_number(context, script, bytecode)
        f_name    = file_name(context, script)
        logger.debug("interrupt_handler #{f_name} #{line_num}")
        JSTRAP_CONTINUE
      end

      def new_script_hook(filename, linenum)
        logger.debug("new_script_hook: #{filename} #{linenum}")
      end

      def destroy_script_hook
        logger.debug("destroy_script_hook")
      end

      def debugger_handler(context, script, bytecode)
        line_num  = line_number(context, script, bytecode)
        f_name    = file_name(context, script)
        logger.debug("debugger_handler: #{bytecode}")
        JSTRAP_CONTINUE
      end

      def source_handler(filename, line_number, str)
        logger.debug("source_handler: #{filename}(#{line_number}): #{str}")
      end

      # +call_hook+ is called before and after script execution.  +before+
      # is +true+ if before, +false+ otherwise.
      def execute_hook(context, stack_frame, before, ok)
        logger.debug("execute_hook: #{before} #{ok}")
      end

      # +call_hook+ is called before and after a function call.  +before+
      # is +true+ if before, +false+ otherwise.
      def call_hook(before, ok)
        logger.debug("call_hook: #{before} #{ok}")
      end

      def object_hook(is_new)
        logger.debug("object_hook: #{is_new}")
      end

      # This hook can change the control
      def throw_hook(bytecode)
        logger.debug("throw_hook: #{bytecode}")
        JSTRAP_CONTINUE
      end

      def debug_error_hook(message)
        logger.debug("debug_error_hook: #{message}")
      end
    end
  end
end
