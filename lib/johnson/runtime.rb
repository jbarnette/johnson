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
    
    def load(*files)
      files.map { |f| delegate.evaluate(File.read(f).gsub(/\A#!.*$/, ''), f, 1) }.last
    end

    ###
    # Johnson.require on each file in +files+
    def require(*files)
      files.each do |file|
        evaluate("Johnson.require('#{file}');")
      end
    end

    ###
    # Compile +script+ with +filename+ and +linenum+
    def compile(script, filename=nil, linenum=nil)
      delegate.compile(script, filename, linenum)
    end

    ###
    # Yield to +block+ in +filename+ at +linenum+
    def break(filename, linenum, &block)
      delegate.break(filename, linenum, &block)
    end

    def evaluate_compiled_script(script)
      delegate.evaluate_compiled_script(script)
    end

    private
    # Called by SpiderMonkey's garbage collector to determine whether or
    # not it should GC
    def should_sm_gc?
      false
    end
  end
end
