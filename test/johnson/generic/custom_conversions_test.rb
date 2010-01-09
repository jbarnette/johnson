require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class CustomConversionsTest < Johnson::TestCase
    def test_ruby_time_round_trips
      @runtime['t'] = t = Time.now
      assert_js_equal(t, 't')
    end

    def test_ruby_time_wrappers_are_equal
      @runtime['t'] = t = Time.now
      @runtime['t2'] = t
      assert_js('t == t2')
    end

    def test_ruby_time_has_js_methods
      @runtime['t'] = t = Time.now
      assert_js_equal(t.year, 't.getFullYear()')
    end

    def test_ruby_date_round_trips
      @runtime['t'] = t = Date.today
      assert_js_equal(t, 't')
    end

    def test_ruby_date_has_js_methods
      @runtime['t'] = t = Date.today
      assert_js_equal(t.year, 't.getFullYear()')
    end

    def test_js_date_is_ruby_date
      @runtime.evaluate %{this.t = new Date('Jul 22, 2009 12:34:56');}

      assert_kind_of(Date, @runtime['t'])
    end

    def test_js_date_round_trips
      @runtime.evaluate %{this.t = new Date('Jul 22, 2009 12:34:56');}
      @runtime['t2'] = @runtime['t']

      assert_js('t == t2')
    end

    def test_js_date_has_ruby_methods
      @runtime.evaluate %{this.t = new Date('Jul 22, 2009 12:34:56');}

      assert_equal('Wed, 22 July, 2009', @runtime['t'].strftime('%a, %d %B, %Y'))
    end
  end
end
