module UsersHelper
  def render_users_list(users)
    content_tag :ul do
      users.map { |user| content_tag :li, user.email }.join.html_safe
    end
  end
end
