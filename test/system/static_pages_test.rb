require "application_system_test_case"

class StaticPagesSystemTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_path
    assert_selector "h1", text: "HIT'EMS"
    assert_selector "h2", text: "使い方"
  end
end
