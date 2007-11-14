require File.dirname(__FILE__) + "/helper"

class SelectorTest < SelectorTestCase
  class MySelector < Selector; end

  def test_equals2
    first = Selector.new(1)
    second = Selector.new(1)
    assert_equal first, second


    third = Selector.new(2)
    assert_not_equal first, third

    fourth = MySelector.new(1)
    assert_equal first, fourth
    assert_not_equal first, 1
  end
end
