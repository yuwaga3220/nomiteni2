module UsersHelper
    # 引数で与えられたユーザーのアイコン画像を返す
    # 自前でアップロードした画像があればそれを優先し、次にGoogleアカウントのプロフィール画像、
    # どちらもなければGravatarを使う
    def gravatar_for(user, options = { size: 80 })
      size = options[:size]
      image_style = "width: #{size}px; height: #{size}px; object-fit: cover;"
      if user.avatar.attached?
        image_tag(user.avatar.variant(:display), alt: user.name, class: "gravatar", style: image_style)
      elsif user.avatar_url.present?
        image_tag(user.avatar_url, alt: user.name, class: "gravatar", style: image_style)
      else
        gravatar_id  = Digest::MD5.hexdigest(user.email.downcase)
        gravatar_url =
          "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
        image_tag(gravatar_url, alt: user.name, class: "gravatar", style: image_style)
      end
    end
end
