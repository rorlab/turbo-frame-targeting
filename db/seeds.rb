# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

10.times do
  post = Post.create do |p|
    p.title = Faker::Lorem.sentence(word_count: 5)
    p.content = Faker::Lorem.paragraph(sentence_count: 10)
  end
  puts "##{post.id} #{post.title}"
end