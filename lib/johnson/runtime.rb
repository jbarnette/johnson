module Johnson
  ###
  # An interface to a JavaScript engine.
  class Runtime

    PRELUDE_PATH = File.expand_path File.dirname(__FILE__) +
      "/js/prelude.js" # :nodoc:
    CORE_PATH = File.expand_path File.dirname(__FILE__) +
      "/js/core.js" # :nodoc:

    PRELUDE = IO.read PRELUDE_PATH # :nodoc:
    CORE = IO.read CORE_PATH # :nodoc:

    ###
    # Deprecated: Previously, returned the underlying JavaScript engine
    # instance. Now returns self.
    def delegate
      self
    end

     ###
     # Create a new Runtime instance, using the default JavaScript
     # engine.
     #
     # Optionally takes a parameter specifying which engine to use, but
     # this is deprecated; instead, just create an instance of that
     # engine's runtime directly.
     #
     # options passed to the underlying runtime
     #   Use size to specify heap limit
     #
     # :call-seq:
     #   new(runtime_class=nil, options)
     #
     def self.new(*args)
       return super if self < Johnson::Runtime

       delegate = args.first
       if delegate.is_a? Class
         delegate.new
       elsif !delegate.nil? && !delegate.is_a?( Hash )
         delegate
       else
         default.new( *args )
       end
     end

    ###
    # Install the Johnson prelude into this runtime environment.
    def initialize # :notnew:
      evaluate PRELUDE, PRELUDE_PATH, 1
      global.Johnson.runtime = self
      global['Ruby'] = Object
      evaluate CORE, CORE_PATH, 1
    end

    ###
    # Access the +key+ property of the JavaScript +global+ object.
    def [](key)
      global[key]
    end

    ###
    # Set the +key+ property of the JavaScript +global+ object to
    # +value+.
    def []=(key, value)
      global[key] = value
    end


    ###
    # Execute the JavaScript source in +script+. If supplied, the script
    # is marked as starting on line +linenum+ of +filename+.
    #
    # Equivalent to calling RubyLandScript#execute on the result of
    # Runtime#compile.
    def evaluate(script, filename = nil, linenum = nil)
      return nil if script.nil?
      compiled_script = compile(script, filename, linenum)
      evaluate_compiled_script(compiled_script)
    end

    ###
    # The JavaScript unique Global Object.
    def global
      raise NotImplementedError
    end

    ###
    # Load and execute the named JavaScript +files+.
    #
    # Checks for (and skips) a shebang line at the top of any of them.
    def load(*files)
      files.map { |f|
        evaluate(File.read(f).gsub(/\A#!.*$/, ''), f, 1)
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
    def compile(script, filename=nil, linenum=nil, global=nil)
      raise NotImplementedError
    end

    ###
    # Evaluates the given JS script, that should have been returned by a
    # previous call to #compile().
    def evaluate_compiled_script(script,scope=nil)
      raise NotImplementedError
    end

    def current_stack
      global.Johnson.getStack
    end

    def parse_js_stack(full_stack, jsex=nil)
      full_js_stack = full_stack.split(/\n/)
      short_js_stack = current_stack.split(/\n/)

      upper, lower = StackDeck.split_list(full_js_stack, short_js_stack)
      stack = upper.map {|s| StackDeck::Frame::JavaScript.parse(s) }

      if jsex
        top = StackDeck::Frame::JavaScript.new(nil, jsex['fileName'], jsex['lineNumber'])
        stack.unshift top unless top.same_line?(stack.first)
      end

      stack
    end
    private :parse_js_stack

    def raise_js_exception(jsex)
      exception_source = caller(2)

      case jsex
      when Exception
        if stack = jsex.send(:remove_instance_variable, :@js_stack)
          jsex.append_to_stack_deck parse_js_stack(stack)
        end
        raise jsex
      when String
        ex = Johnson::Error.new(jsex)
        ex.set_backtrace exception_source
      when Johnson::RubyLandProxy
        ex = Johnson::Error.new(jsex['message'] || jsex.to_s, jsex)
        ex.set_backtrace exception_source

        if stack = jsex['stack']
          ex.append_to_stack_deck parse_js_stack(stack, jsex)
        end
      else
        ex = Johnson::Error.new(jsex.inspect)
        ex.set_backtrace exception_source
      end

      raise ex
    end

    @runtimes = []

    class << self

      attr_reader :runtimes

      private

      def default
        if @runtimes.empty?
          require "johnson/tracemonkey"
        end
        @runtimes[0]
      end

      def inherited runtime
        @runtimes << runtime
      end

    end

  end
end
