module Johnson
  class Context
    attr_reader :delegate
    
    def initialize(delegate=Johnson::SpiderMonkey::Context)
      @delegate = delegate.is_a?(Class) ? delegate.new : delegate
      evaluate(Johnson::PRELUDE, 'Johnson::PRELUDE')
    end
    
    def [](key)
      delegate[key.to_s]
    end
    
    def []=(key, value)
      delegate[key.to_s] = value
    end
    
    def evaluate(expression, filename=nil, linenum=nil)
      return nil if expression.nil?
      delegate.evaluate(expression, filename, linenum)
    end
    
    def global
      delegate.global
    end
    
    def load(file)
      delegate.evaluate(IO.read(file), file)
    end
  end
end
