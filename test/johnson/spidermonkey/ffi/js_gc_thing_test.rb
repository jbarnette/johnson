require File.expand_path(File.join(File.dirname(__FILE__), "/../../../helper"))

module Johnson
  module SpiderMonkey

    class JSGCThingTest < Johnson::TestCase

      def setup
        @runtime = Johnson::Runtime.new
        @context = @runtime.delegate.context
      end

      def teardown
        @runtime.delegate.destroy
      end

      def test_can_be_initialized_with_a_pointer
        js_object = JSGCThing.new(@context, SpiderMonkey.JS_NewObject(@context, nil, nil, nil))
      end

      def test_can_root_unroot_value
        js_string = JSGCThing.new(@context, SpiderMonkey.JS_NewStringCopyN(@context, "hola", "hola".size))
        js_string.root
        js_string.unroot
        assert(js_string.unrooted?)
      end

      def test_can_do_named_root
        js_string = JSGCThing.new(@context, SpiderMonkey.JS_NewStringCopyN(@context, "hola", "hola".size))
        js_string.root(binding, 'string')
        js_string.unroot
        assert(js_string.unrooted?)
      end

      def test_block_syntax
        js_string = JSGCThing.new(@context, SpiderMonkey.JS_NewStringCopyN(@context, "hola", "hola".size))
        js_string.root do
          SpiderMonkey.STRING_TO_JSVAL(js_string.to_ptr)
        end
        assert(js_string.unrooted?)
      end

      def test_pointer_equals
        value_ptr = SpiderMonkey.JS_NewStringCopyN(@context, "hola", "hola".size)
        js_rootable = JSGCThing.new(@context, value_ptr)
        assert_equal(true, value_ptr == js_rootable.to_ptr)
      end

    end

  end
end
