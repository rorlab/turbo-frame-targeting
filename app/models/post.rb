class Post < ApplicationRecord
  broadcasts_to ->(post) { "all-posts" }
end
