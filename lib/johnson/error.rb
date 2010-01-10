module Johnson
  class Error < StandardError
    attr_accessor :original_exception
    def initialize(message, original=nil)
      super(message)
      @original_exception = original unless original.nil?
    end
  end
end
