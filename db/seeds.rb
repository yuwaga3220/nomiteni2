# メインのサンプルユーザーを1人作成する（重複時は既存を利用）
User.find_or_create_by!(email: "example@railstutorial.org") do |u|
  u.name  = "Example User"
  u.password = "foobarbar"
  u.password_confirmation = "foobarbar"
  u.admin = true
  u.activated = true
  u.activated_at = Time.zone.now
end

# 追加のユーザーをまとめて生成する
30.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  User.find_or_create_by!(email: email) do |u|
    u.name = name
    u.password = password
    u.password_confirmation = password
    u.activated = true
    u.activated_at = Time.zone.now
  end
end

users = User.order(:created_at)
users.each do |user|
  # 既存の大会は一旦削除して、0〜3件を再生成する
  user.tournaments.delete_all
  rand(0..3).times do
    user.tournaments.create!(
      title: Faker::Lorem.sentence(word_count: 3),
      description: Faker::Lorem.sentence(word_count: 10),
      held_on: Faker::Date.forward(days: 60),
      venue: Faker::Address.city
    )
  end
end
