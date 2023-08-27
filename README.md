# Turbo Frame: Targeting

레일스 7 에서는 디폴트 프론트엔드 프레임워크로 hotwire를 사용하고 있습니다. hotwire 의 터보 프레임을 사용할 때, 터보 프레임 안에서 링크나 폼 서브밋 이벤트가 발생하면, 동일한 터보 프레임을 타겟으로 서버 응답 결과를 업데이트 하게 됩니다. 이와 같이 특정 터보 프레임으로 페이지 이동을 제한하는 것을 `scoped navigation` 이라고 합니다. 따라서 터보 기능을 사용할 때 페이지 이동을 body 전체로 제한하는 것을 터보 드라이브, body 내의 특정 부분으로 제한하는 것을 터보 프레임으로 생각할 수 있을 것 같습니다.  

![image-20230827203551439](/public/image-20230827203551439.png)

터보 프레임을 사용할 경우 서버 응답 결과를 동일한 터보 프레임이 아니라 터보 드라이브로   전체 페이지를 업데이트 하고자 한다면 터보 프레임 태그 안에 `target` 이라는 속성을 추가하고 `_top` 을 지정할 수 있습니다.

![image-20230827204814343](/public/image-20230827204814343.png)

디폴트 상태에서 `target` 속성값을 지정하지 않을 경우에는 `_self` 값이 생략된 것으로 생각하면 됩니다. 테스트해 본 결과  `target` 속성을 지정하지 않은 경우와 `target` 속성 `_self` 로 지정한 경우 동일한 결과를 보여 주었습니다.

![image-20230827204843699](/public/image-20230827204843699.png)

-------

이해를 돕기 위해서 `turbo-frame-targeting` 이라는 프로젝트를 생성하겠습니다. 

```bash
rails new turbo-frame-targeting && cd turbo-frame-targeting
```

프로젝트 셋업 명령을 실행하겠습니다. 

```bash
bin/setup
```

`title` 과 `content` 속성을 가지는 `Post` 리소스를 `scaffolding` 하고 `db:migrate` 명령을 실행하겠습니다. 

```bash
bin/rails g scaffold Post title content:text && bin/rails db:migrate
```

`config/routes.rb` 파일을 열고 루트 경로를 정의하겠습니다. 

```rb
root "posts#index"
```

테스트용 데이터를 추가하기 위해서 `faker` 젬을 추가한 후 번들 인스톨하겠습니다. 

```bash
bundle add faker
```

`db/seeds.rb` 파일을 열고 하단에 아래의 코드라인을 추가합니다.

```ruby
10.times do
  post = Post.create do |p|
    p.title = Faker::Lorem.sentence(word_count: 5)
    p.content = Faker::Lorem.paragraph(sentence_count: 10)
  end
  puts "##{post.id}. #{post.title}"
end
```

그리고 터미널에서 `db:seed` 명령을 실행하면 `posts` 테이블에 10개의 테스트용 레코드가 생성된 것을 확인 할 수 있습니다.

```bash
bin/rails db:seed
```

이제 터미널에서 로컬 웹서버를 실행하고

```bash 
bin/rails server
```

크롬 브라우저에서 `localhost:3000` 으로 이동합니다. 

`views/posts/index` 파일을 열고 아래와 같이 코드라인을 업데이트 합니다.

```erb
<p style="color: green"><%= notice %></p>

<%= turbo_stream_from "all-posts" %>

<div class='page-header'>
  <h1>Posts</h1>
  <p>
    <%= link_to "New post", new_post_path, data: { turbo_frame: 'post'} %>
  </p>
</div>

<div class='container'>
  <div class='list'>
    <ul id="posts">
      <% @posts.each do |post| %>
        <li id="<%= dom_id post %>">
          <%= link_to post.title, post, data: { turbo_frame: "post" } %>
        </li>
      <% end %>
    </ul>
  </div>
  <div class='content'>
    <%= turbo_frame_tag :post %>
  </div>
</div>
```

3번 코드라인은 `all-posts` 채널로 들어 오는 터보 스트림을 `subscribe` 하도록 해 줍니다. 23번 코드라인을 추가하게 되면, `post` 터보 프레임에서 데이터 변경 이벤트가 발생할 때 백그라운로 `all-posts` 채널로 메시지가 `broadcast` 되도록 할 수 있습니다. 이를 위해서는 `app/models/post.rb` 파일을 열고 아래와 같이 업데이트 합니다.  

```ruby
class Post < ApplicationRecord
  broadcasts_to ->(post) { "all-posts" }
end
```

`app/views/posts/_post.html.erb` 파일을 열고 아래와 같이 변경하고

```erb
<li id="<%= dom_id post %>"><%= link_to post.title, post, data: { turbo_frame: 'post' } %></li>
```

대신에 `app/views/posts/_post_for_show.html.erb` 파일을 추가하고 아래와 같이 코드를 작성합니다.

```erb
<div id="<%= dom_id post %>">
  <p>
    <strong>Title:</strong>
    <%= post.title %>
  </p>

  <p>
    <strong>Content:</strong>
    <%= post.content %>
  </p>

</div>
```

`views/posts/show.html.erb` 파일을 열고 링크 클릭시 업데이트할 터보 프레임을 지정합니다. 

```erb
<%= turbo_frame_tag :post do %>
  <p style="color: green"><%= notice %></p>

  <%= render partial: 'posts/post_for_show', locals: { post: @post } %>

  <div>
    <%= link_to "Edit this post", edit_post_path(@post) %> |
    <%= link_to "Back to posts", posts_path, data: { turbo_frame: '_self'} %>

    <%= button_to "Destroy this post", @post, method: :delete %>
  </div>
<% end %>
```

스타일링을 위해서 app/assets/stylesheets/application.css 파일을 열고 아래와 같이 추가합니다. 

```css
.container {
  display: flex;
  width: 100%;
}

.list {
  width: 50%;
  padding-inline: 1rem;
}

.content {
  width: 50%;
  border: 1px solid #eaeaea;
  background-color: #eaeaea;
  border-radius: 0.5rem;
  padding-inline: 1rem;
  padding-bottom: 1rem;
  position: relative;
}

.content::after {
  content: 'turbo-frame id="post"';
  border: 1px solid red;
  border-radius: 0.45rem 0.45rem 0 0;
  width: 100%;
  position: absolute;
  top: 0;
  left: 0;
  box-sizing: border-box;
  font-size: .6rem;
  text-align: center;
  color: #9d9d9d;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
```

`new.html.erb` 

```erb
<%= turbo_frame_tag :post do %>
  <h1>New post</h1>

  <%= render "form", post: @post %>

  <br>

  <div>
    <%= link_to "Back to posts", posts_path %>
  </div>
<% end %>
```

`edit.html.erb`

```erb
<%= turbo_frame_tag :post do %>
  <h1>Editing post</h1>

  <%= render "form", post: @post %>

  <br>

  <div>
    <%= link_to "Show this post", @post %> |
    <%= link_to "Back to posts", posts_path %>
  </div>
<% end %>
```

이제 브라우저에서 임의의 `post` 링크를 클릭하면, 

![image-20230827211016978](/public/image-20230827211016978.png)

이번에는 `views/posts/index.html.erb` 파일을 열고 `turbo_frame` 값을 `_top` 으로 변경합니다.

```erb
<div class='container'>
  <div class='list'>
    <ul id="posts">
      <% @posts.each do |post| %>
        <li id="<%= dom_id post %>">
          <%= link_to post.title, post, data: { turbo_frame: "_top" } %>
        </li>
      <% end %>
    </ul>
  </div>
  <div class='content'>
    <%= turbo_frame_tag :post %>
  </div>
</div>
```

이제 인덱스 페이지 내에서  임의의 `post ` 링크를 클릭하면  `show` 액션 뷰 페이지가 전체 페이지로 보이게 됩니다. 터보 드라이브가 작동하는 것과 동일한 결과를 보여주게 됩니다. 

![image-20230827212059820](/public/image-20230827212059820.png)

그리고 `show` 액션 뷰 템플릿 파일에서 "`Back to posts`" 링크와 "`Destroy this post`" 버튼의 `turbo_frame` 키 값을 `_top` 으로 변경하면 클릭 시에 인덱스 페이지로 이동합니다.

지금까지 터브 프레임의 `target` 사용법에 대해서 알아 보았습니다. 

감사합니다.
