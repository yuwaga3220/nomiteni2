require "application_system_test_case"

class StaticPagesSystemTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_path
    assert_selector "h3", text: "Hit'Emsへようこそ！"
  end
end
