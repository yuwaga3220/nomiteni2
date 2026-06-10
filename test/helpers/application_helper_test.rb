require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal "Tennis'Ems", full_title
    assert_equal "Test | Tennis'Ems", full_title("Test")
  end
end
