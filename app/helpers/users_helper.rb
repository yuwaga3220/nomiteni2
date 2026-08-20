module UsersHelper
    # 引数で与えられたユーザーのアイコン画像を返す
    # Googleアカウントのプロフィール画像があればそちらを優先し、なければGravatarを使う
    def gravatar_for(user, options = { size: 80 })
      size = options[:size]
      if user.avatar_url.present?
        image_tag(user.avatar_url, alt: user.name, class: "gravatar")
      else
        gravatar_id  = Digest::MD5.hexdigest(user.email.downcase)
        gravatar_url =
          "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
        image_tag(gravatar_url, alt: user.name, class: "gravatar")
      end
    end
end
