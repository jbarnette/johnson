module Johnson
  module Parser
    class SyntaxError < RuntimeError
      attr_accessor :message, :file_name, :line_number
      def initialize(message, file_name, line_number)
        super("#{message} in (#{file_name || "nil"}): #{line_number}")
        @message      = message
        @file_name    = file_name
        @line_number  = line_number
      end
    end
  end
end
