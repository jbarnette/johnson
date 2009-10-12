module Johnson #:nodoc:
  module TraceMonkey #:nodoc:
    class Context # native
      def initialize(runtime, options={})
        @runtime = runtime
        initialize_native(runtime, options)
      end
    end
  end
end
