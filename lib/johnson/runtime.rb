module Johnson
  class Runtime
    attr_reader :delegate
    
    def initialize(delegate=Johnson::SpiderMonkey::Runtime)
      @delegate = delegate.is_a?(Class) ? delegate.new : delegate
      evaluate(Johnson::PRELUDE, "Johnson::PRELUDE", 1)
      global.Johnson.runtime = self
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
      delegate.evaluate(IO.read(file), file, 1)
    end

    private
    # Called by SpiderMonkey's garbage collector to determine whether or
    # not it should GC
    def should_sm_gc?
      false
    end
  end
end
