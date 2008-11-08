require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class PrototyperTest < Johnson::TestCase
    def test_prototype_for_ruby_class_is_empty_by_default
      assert_kind_of Johnson::Prototyper, @runtime.evaluate("Ruby.Array.prototype")
    end

    def test_prototype_stays_the_same
      assert_same @runtime.evaluate("Ruby.Array.prototype"),
        @runtime.evaluate("Ruby.Array.prototype")
    end

    def test_prototype_property_ignores_assignment
      prototype = @runtime.evaluate("Ruby.Array.prototype")
      
      @runtime.evaluate("Ruby.Array.prototype = {}")
      assert_same prototype, @runtime.evaluate("Ruby.Array.prototype")
    end

    def assert_instance_method klass, name
      assert klass.instance_methods.include?(name),
        "expected #{klass.inspect} to have instance method #{name.inspect}"
    end
    
    def assert_no_instance_method klass, name
      assert !klass.instance_methods.include?(name),
        "expected #{klass.inspect} not to have instance method #{name.inspect}"
    end

    def test_assigning_simple_value_creates_attr_accessor_with_default
      assert_no_instance_method Array, "foo"

      @runtime.evaluate("Ruby.Array.prototype.foo = 42")
      assert_instance_method Array, "foo"

      assert_equal(42, [].foo)
    end
    
    def test_assigning_function_creates_rubyland_wrapper
      assert_no_instance_method Array, "newLength"
      
      @runtime.evaluate <<-END
        Ruby.Array.prototype.newLength = function() {
          return this.length();
        }
      END
      
      assert_instance_method Array, "newLength"
      
      a = %w(one two three)
      assert_equal a.length, a.newLength
    end
    
    def test_prototyper_keeps_track_of_methods_defined_from_prototype
      
    end
    
    def test_retrieving_prototype_function_from_instance_does_the_right_thing
      @runtime.evaluate("Ruby.Array.prototype.foo = function() {}")
      assert_js("(new Ruby.Array).foo === Ruby.Array.prototype.foo")
    end
  end
end

