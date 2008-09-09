require "optparse"

module Johnson #:nodoc:
  module CLI #:nodoc:
    class Options #:nodoc:
      class << self
        alias_method :parse!, :new
      end
      
      attr_reader :arguments
      attr_reader :expressions
      attr_reader :files_to_preload
      attr_reader :files_to_evaluate
      attr_reader :load_paths
      attr_reader :paths_to_require
    
      def initialize(*args)
        @arguments = []
        @expressions = []
        @load_paths = []
        @files_to_preload = []
        @paths_to_require = []

        argv = args.flatten
        
        if index = argv.index("--")
          @arguments = argv[(index+1)..-1]
          argv = argv[0..index]
        end

        parser = OptionParser.new do |parser|
          parser.banner = "Usage: johnson [options] [file.js...] [-- jsargs...]"
          parser.version = Johnson::VERSION

          parser.on("-e [EXPRESSION]", "Evaluate [EXPRESSION] and exit") do |expression|
            @expressions << expression
          end
      
          parser.on("-I [DIRECTORY]", "Specify $LOAD_PATH directories") do |dir|
            @load_paths << dir
          end

          parser.on("-i [FILE]", "Evaluate [FILE] before interaction") do |file|
            @files_to_preload << file
          end
          
          parser.on("-r [PATH]", "Require [PATH] before executing") do |path|
            @paths_to_require << path
          end
      
          parser.on("-h", "-?", "--help", "Show this message") do
            puts parser
            exit
          end
      
          parser.on("-v", "--version", "Show Johnson's version (#{Johnson::VERSION})") do
            puts Johnson::VERSION
            exit
          end  
        end
        
        parser.parse!(argv)
        @files_to_evaluate = argv.dup
      end 
    end
  end
end
