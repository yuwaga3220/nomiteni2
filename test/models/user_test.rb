require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: "Example User",
      email: "user@example.com",
      password: "foobarfoo",
      password_confirmation: "foobarfoo"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "    "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = "    "
    assert_not @user.valid?
  end

  test "name should not be too long" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "email should not be too long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[
      user@example.com
      USER@foo.COM
      A_US-ER@foo.bar.org
      first.last@foo.jp
      alice+bob@baz.cn
    ]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[
      user@example,com
      user_at_foo.org
      user.name@example.
      foo@bar_baz.com
      foo@bar+baz.com
    ]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email address should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email addresses should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 8
    assert_not @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 7
    assert_not @user.valid?
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, "")
  end

  test "associated tournaments should be destroyed" do
    @user.save
    @user.tournaments.create!(title: "春季テニス大会")
    assert_difference "Tournament.count", -1 do
      @user.destroy
    end
  end

  test "score should be ten points per correctly predicted match in the given tournament" do
    tournament = tournaments(:orange)
    match = tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob), winner: participants(:alice))
    users(:michael).predictions.create!(match: match, predicted_participant: participants(:alice), points: 10)
    assert_equal 10, users(:michael).score(tournament)
  end

  test "score should not count wrong predictions" do
    tournament = tournaments(:orange)
    match = tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob), winner: participants(:alice))
    users(:michael).predictions.create!(match: match, predicted_participant: participants(:bob), points: 0)
    assert_equal 0, users(:michael).score(tournament)
  end

  test "score should not count predictions made in a different tournament" do
    tournament = tournaments(:orange)
    other_tournament = tournaments(:ants)
    match = tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob), winner: participants(:alice))
    other_match = other_tournament.matches.create!(round: 1, participant1: participants(:carol), participant2: participants(:dave), winner: participants(:carol))
    users(:michael).predictions.create!(match: match, predicted_participant: participants(:alice), points: 10)
    users(:michael).predictions.create!(match: other_match, predicted_participant: participants(:carol), points: 10)
    assert_equal 10, users(:michael).score(tournament)
  end

  test "score_percentile should reflect rank among all activated users for the given tournament" do
    tournament = tournaments(:orange)
    match = tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob), winner: participants(:alice))
    users(:michael).predictions.create!(match: match, predicted_participant: participants(:alice), points: 10)
    total_activated = User.where(activated: true).count
    expected_percentile = ((1.0 / total_activated) * 100).round
    assert_equal expected_percentile, users(:michael).score_percentile(tournament)
  end

  test "score_percentile should not count a user's predictions from other tournaments" do
    tournament = tournaments(:orange)
    other_tournament = tournaments(:ants)
    match = tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob), winner: participants(:alice))
    other_match = other_tournament.matches.create!(round: 1, participant1: participants(:carol), participant2: participants(:dave), winner: participants(:carol))
    # archerは別大会でしか予想していないので、この大会のランキングでは0点扱いになるはず
    users(:archer).predictions.create!(match: other_match, predicted_participant: participants(:carol), points: 10)
    users(:michael).predictions.create!(match: match, predicted_participant: participants(:alice), points: 10)
    total_activated = User.where(activated: true).count
    expected_percentile = ((1.0 / total_activated) * 100).round
    assert_equal expected_percentile, users(:michael).score_percentile(tournament)
  end
end
