require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal "Hit'Ems", full_title
    assert_equal "Test | Hit'Ems", full_title("Test")
  end
end
