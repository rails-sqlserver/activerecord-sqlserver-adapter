class Post < ActiveRecord::Base
  scope :ranked_by_comments, -> { order("comments_count DESC, id ASC") }
end
