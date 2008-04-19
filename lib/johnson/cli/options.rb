require "optparse"

module Johnson
  module CLI
    class Options
      class << self
        alias_method :parse!, :new
      end
      
      attr_reader :expressions, :load_paths, :files_to_preload, :files_to_evaluate
    
      def initialize(*args)
        argv = args.flatten
        @expressions = []
        @load_paths = []
        @files_to_preload = []
        @files_to_evaluate = []

        parser = OptionParser.new do |parser|
          parser.banner = "Usage: johnson [options] [files...]"
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
      
          parser.on("-i [FILE]", "Evaluate [FILE] before interaction") do |file|
            @files_to_preload << file
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
        argv.each { |f| @files_to_evaluate << f }
      end 
    end
  end
end
