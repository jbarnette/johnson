module Johnson
  ###
  # An interface to a JavaScript engine.
  class Runtime

    PRELUDE_PATH = File.expand_path File.dirname(__FILE__) +
      "/js/prelude.js"

    PRELUDE = IO.read PRELUDE_PATH

    ###
    # The underlying JavaScript engine instance.
    attr_reader :delegate

    ###
    # Create a new Runtime instance, using the given +delegate+ class,
    # or a Johnson::SpiderMonkey::Runtime by default.
    def initialize(delegate=Johnson::SpiderMonkey::Runtime)
      @delegate = delegate.is_a?(Class) ? delegate.new : delegate
      evaluate PRELUDE, PRELUDE_PATH, 1
      global.Johnson.runtime = self
    end

    ###
    # Access the +key+ property of the JavaScript +global+ object.
    def [](key)
      delegate[key]
    end

    ###
    # Set the +key+ property of the JavaScript +global+ object to
    # +value+.
    def []=(key, value)
      delegate[key] = value
    end

    ###
    # Execute the JavaScript source in +script+. If supplied, the script
    # is marked as starting on line +linenum+ of +filename+.
    #
    # Equivalent to calling RubyLandScript#execute on the result of
    # Runtime#compile.
    def evaluate(script, filename=nil, linenum=nil)
      return nil if script.nil?
      delegate.evaluate(script, filename, linenum)
    end

    ###
    # The JavaScript unique Global Object.
    def global
      delegate.global
    end

    ###
    # Load and execute the named JavaScript +files+.
    #
    # Checks for (and skips) a shebang line at the top of any of them.
    def load(*files)
      files.map { |f|
        delegate.evaluate(File.read(f).gsub(/\A#!.*$/, ''), f, 1)
      }.last
    end

    ###
    # Search the Ruby load path for each of the named +files+, and
    # evaluate them *if they have not yet been loaded*.
    #
    # Calls Johnson.require() in JavaScript on each filename in turn.
    def require(*files)
      files.each do |file|
        evaluate("Johnson.require('#{file}');")
      end
    end

    ###
    # Compile the JavaScript source in +script+. If supplied, the script
    # is marked as starting on line +linenum+ of +filename+.
    def compile(script, filename=nil, linenum=nil)
      delegate.compile(script, filename, linenum)
    end

    def evaluate_compiled_script(script)
      delegate.evaluate_compiled(script)
    end
  end
end
