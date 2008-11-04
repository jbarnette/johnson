module Johnson
  class Prototyper
    def initialize target
      raise "Module or class required" unless target.is_a? Module
      @target = target
    end

    def []= key, value
      if value.respond_to?(:function?) && value.function?
        @target.__send__ :define_method, key do |*args|
          value.apply(self, Johnson.mark_for_conversion_by_value(args))
        end
      else
        Johnson::Prototyper.defaults_for(@target)[key] = value

        @target.class_eval <<-END, __FILE__, __LINE__
          attr_writer "#{key}"

          def #{key}
            defined?(@#{key}) ? @#{key} :
              @#{key} = Johnson::Prototyper.defaults_for(#{@target.name})["#{key}"]
          end
        END
      end
    end

    def self.defaults_for(target)
      (@defaults ||= Hash.new { |h,k| h[k] = {} })[target]
    end
  end
end

