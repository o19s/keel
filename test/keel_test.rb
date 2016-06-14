require 'test_helper'

class KeelTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Keel::VERSION
  end
end
