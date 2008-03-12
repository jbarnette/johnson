require "forwardable"

module Johnson
  class Context
    extend Forwardable
    
    attr_reader :delegate
    def_delegators :delegate, :evaluate, :[], :[]=
    
    def initialize(delegate=Johnson::SpiderMonkey::Context)
      @delegate = delegate.is_a?(Class) ? delegate.new : delegate
    end
  end
end
