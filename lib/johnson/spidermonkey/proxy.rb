module Johnson
  module SpiderMonkey
    class Proxy # native
      def to_proc
        @proc ||= Proc.new { |*args| call(*args) }
      end
      
      def method_missing(sym, *args)
        name = sym.to_s
        assignment = "=" == name[-1, 1]
        
        # default behavior if the slot's not there
        return super unless assignment || respond_to?(sym)
        
        # for arity 0, treat it as a get
        return self[name] if args.empty?
        
        # arity 1 and quacking like an assignment, treat it as a set
        return self[name[0..-2]] = args[0] if assignment && 1 == args.size
        
        # okay, must really be a function (native code)
        call_property(name, *args) # FIXME
      end
    end
  end
end
