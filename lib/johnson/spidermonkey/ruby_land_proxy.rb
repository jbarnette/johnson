module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class RubyLandProxy # native
      def initialize
        raise Johnson::Error, "#{self.class.name} is an internal support class."
      end
      
      private :initialize
      
      # FIXME: need to revisit array vs non-array proxy, to_a/to_ary semantics, etc.
      include Enumerable
      alias_method :size, :length
      alias_method :to_ary, :to_a
      
      def to_proc
        @proc ||= Proc.new { |*args| call(*args) }
      end

      def call(*args)
        call_using(runtime.global, *args)
      end

      def call_using(this, *args)
        native_call(this, *args)
      end
      
      def inspect
        toString
      end
      
      def method_missing(sym, *args, &block)
        args << block if block_given?
        
        name = sym.to_s
        assignment = "=" == name[-1, 1]
        
        # default behavior if the slot's not there
        return super unless assignment || respond_to?(sym)
        
        unless function_property?(name)
          # for arity 0, treat it as a get
          return self[name] if args.empty?

          # arity 1 and quacking like an assignment, treat it as a set
          return self[name[0..-2]] = args[0] if assignment && 1 == args.size
        end
        
        # okay, must really be a function
        call_function_property(name, *args)
      end
    end
  end
end
