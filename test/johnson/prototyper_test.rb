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

    def test_assigning_simple_value_creates_attr_accessor_with_default
      assert !Array.instance_methods.include?("foo"), "there's no 'foo' attribute"

      @runtime.evaluate("Ruby.Array.prototype.foo = 42")
      assert Array.instance_methods.include?("foo"), "now there's a 'foo' attribute"

      assert_equal(42, [].foo)
    end
  end
end

