defmodule HasAWebsite.BlogTest do
  use HasAWebsite.DataCase

  alias HasAWebsite.Blog

  describe "posts" do
    alias HasAWebsite.Blog.Post

    import HasAWebsite.AccountsFixtures, only: [user_scope_fixture: 0]
    import HasAWebsite.BlogFixtures

    @invalid_attrs %{description: nil, title: nil, slug: nil, content: nil, published_at: nil}

    test "list_posts/1 returns all scoped posts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      other_post = post_fixture(other_scope)
      assert Blog.list_posts(scope) == [post]
      assert Blog.list_posts(other_scope) == [other_post]
    end

    test "get_post!/2 returns the post with given id" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      other_scope = user_scope_fixture()
      assert Blog.get_post!(scope, post.id) == post
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(other_scope, post.id) end
    end

    test "create_post/2 with valid data creates a post" do
      valid_attrs = %{description: "some description", title: "some title", slug: "some slug", content: "some content", published_at: ~U[2025-09-25 13:13:00Z]}
      scope = user_scope_fixture()

      assert {:ok, %Post{} = post} = Blog.create_post(scope, valid_attrs)
      assert post.description == "some description"
      assert post.title == "some title"
      assert post.slug == "some slug"
      assert post.content == "some content"
      assert post.published_at == ~U[2025-09-25 13:13:00Z]
      assert post.user_id == scope.user.id
    end

    test "create_post/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.create_post(scope, @invalid_attrs)
    end

    test "update_post/3 with valid data updates the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      update_attrs = %{description: "some updated description", title: "some updated title", slug: "some updated slug", content: "some updated content", published_at: ~U[2025-09-26 13:13:00Z]}

      assert {:ok, %Post{} = post} = Blog.update_post(scope, post, update_attrs)
      assert post.description == "some updated description"
      assert post.title == "some updated title"
      assert post.slug == "some updated slug"
      assert post.content == "some updated content"
      assert post.published_at == ~U[2025-09-26 13:13:00Z]
    end

    test "update_post/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)

      assert_raise MatchError, fn ->
        Blog.update_post(other_scope, post, %{})
      end
    end

    test "update_post/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Blog.update_post(scope, post, @invalid_attrs)
      assert post == Blog.get_post!(scope, post.id)
    end

    test "delete_post/2 deletes the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:ok, %Post{}} = Blog.delete_post(scope, post)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(scope, post.id) end
    end

    test "delete_post/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      assert_raise MatchError, fn -> Blog.delete_post(other_scope, post) end
    end

    test "change_post/2 returns a post changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert %Ecto.Changeset{} = Blog.change_post(scope, post)
    end
  end
end
