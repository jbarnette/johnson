module Johnson
  module SpiderMonkey
    module JSLandProxy #:nodoc:
      def self.send_with_possible_block(target, symbol, args)
        block = args.pop if args.last.is_a?(RubyLandProxy) && args.last.function?
        target.__send__(symbol, *args, &block)
      end
      
      def self.treat_all_properties_as_methods(target)
        def target.js_property?(name); true; end
      end
          
      def self.js_property?(target, name)
        # FIXME: that rescue is gross; handles, e.g., "name?"
        (target.send(:instance_variable_defined?, "@#{name}") rescue false) ||
          (target.respond_to?(:js_property?) && target.__send__(:js_property?, name))
      end
      
      def self.call_proc_by_oid(oid, *args)
        id2ref(oid).call(*args)
      end
      
      def self.id2ref(oid)
        ObjectSpace._id2ref(oid)
      end
      
      def self.autovivified(target, attribute)
        target.send(:__johnson_js_properties)[attribute]
      end

      def self.autovivified?(target, attribute)
        target.respond_to?(:__johnson_js_properties) &&
          target.send(:__johnson_js_properties).key?(attribute)
      end

      def self.autovivify(target, attribute, value)
        (class << target; self; end).instance_eval do
          unless target.respond_to?(:__johnson_js_properties)
            define_method(:__johnson_js_properties) do
              @__johnson_js_properties ||= {}
            end
          end
          
          define_method(:"#{attribute}=") do |arg|
            send(:__johnson_js_properties)[attribute] = arg
          end
          
          define_method(:"#{attribute}") do |*args|
            js_prop = send(:__johnson_js_properties)[attribute]
            if js_prop.is_a?(RubyLandProxy) && js_prop.function?
              js_prop.call_using(self, *args)
            else
              js_prop
            end
          end
        end

        target.send(:"#{attribute}=", value)
      end
    end
  end
end
