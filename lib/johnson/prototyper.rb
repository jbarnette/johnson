module Johnson
  class Prototyper
    attr_reader :defaults, :functions

    def initialize(target)
      raise "Module or class required" unless target.is_a? Module
      @target = target
      @defaults = {}
      @functions = []
    end

    def []=(key, value)
      if value.respond_to?(:function?) && value.function?
        @functions |= [key.to_s]

        @target.__send__ :define_method, key do |*args|
          value.apply(self, Johnson.mark_for_conversion_by_value(args))
        end
      else
        Johnson::Prototyper.for(@target).defaults[key] = value

        @target.class_eval <<-END, __FILE__, __LINE__
          attr_writer "#{key}"

          def #{key}
            defined?(@#{key}) ? @#{key} :
              @#{key} = Johnson::Prototyper.for(#{@target.name}).defaults["#{key}"]
          end
        END
      end
    end
    
    def self.for(target)
      (@prototypes ||= Hash.new { |h,k| h[k] = new(k) })[target]
    end
  end
end

