defmodule HasAWebsite.BlogTest do
  use HasAWebsite.DataCase

  alias HasAWebsite.Blog


  alias HasAWebsite.Blog.Post

  import HasAWebsite.AccountsFixtures, only: [user_scope_fixture: 0, admin_scope_fixture: 0]
  import HasAWebsite.BlogFixtures

  @invalid_attrs %{description: nil, title: nil, slug: nil, content: nil, published_at: nil}

  describe "list_post/0" do
    test "returns all posts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      other_post = post_fixture(other_scope)
      assert Blog.list_posts() == [post, other_post]
    end
  end

  describe "get_post!/1" do
    test "returns the post with given id" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert Blog.get_post!(post.id) == post
    end
  end

  describe "create_post/2" do
    test "valid data creates a post" do
      valid_attrs = %{description: "some description", title: "some cool title", slug: "some-slug", content: "some content"}
      scope = user_scope_fixture()

      assert {:ok, %Post{} = post} = Blog.create_post(scope, valid_attrs)
      assert post.description == "some description"
      assert post.title == "some cool title"
      assert post.slug == "some-slug"
      assert post.content == "some content"
      assert !is_nil(post.published_at)
      assert post.author_id == scope.user.id
    end

    test "invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.create_post(scope, @invalid_attrs)
    end

    test "valid data but no slug creates a post" do
      valid_attrs = %{description: "some description", title: "some cool title", content: "some content"}
      scope = user_scope_fixture()

      assert {:ok, %Post{} = post} = Blog.create_post(scope, valid_attrs)
      assert post.description == "some description"
      assert post.title == "some cool title"
      assert post.slug == "some-cool-slug"
      assert post.content == "some content"
      assert !is_nil(post.published_at)
      assert post.author_id == scope.user.id
    end

    test "an already existing slug returns an error" do
      valid_attrs = %{description: "some description", slug: "some-slug", title: "some cool title", content: "some content"}
      scope = user_scope_fixture()
      {:ok, _post} = Blog.create_post(scope, valid_attrs)

      assert {:error, %Ecto.Changeset{}} = Blog.create_post(scope, %{description: "some description", slug: "some-slug", title: "test title", content: "some content"})
    end

    test "auto-generated slug generates a unique slug" do
      scope = user_scope_fixture()
      {:ok, _post} = Blog.create_post(scope, %{description: "some description", slug: "test", title: "test title", content: "some content"})
      {:ok, post} = Blog.create_post(scope, %{description: "another description", title: "test", content: "more content"})

      assert post.slug != "test"
    end
  end

  describe "update_post/3" do
    test "valid data updates the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      update_attrs = %{description: "some updated description", slug: "new-slug", title: "some updated title", content: "some updated content"}

      assert {:ok, %Post{} = post} = Blog.update_post(scope, post, update_attrs)
      assert post.description == "some updated description"
      assert post.title == "some updated title"
      assert post.slug == "new-slug"
      assert post.content == "some updated content"
      assert !is_nil(post.published_at)
      assert !is_nil(post.last_updated_at)
    end

    test "updated slug maintains unique constraint" do
      valid_attrs = %{description: "some description", slug: "some-slug", title: "some cool title", content: "some content"}
      scope = user_scope_fixture()
      {:ok, _post} = Blog.create_post(scope, valid_attrs)
      post = post_fixture(scope)
      update_attrs = %{title: "some slug", slug: "some-slug"}

      assert {:error, %Ecto.Changeset{}} = Blog.update_post(scope, post, update_attrs)
    end

    test "regenerate_slug set to true regenerates the slug" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      update_attrs = %{title: "new title"}

      assert {:ok, %Post{} = post} = Blog.update_post(scope, post, update_attrs, regenerate_slug: true)
      assert post.slug == "new-title"
    end

    test "regenerate_slug does not regenerate if a new slug is provided" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      update_attrs = %{title: "new title", slug: "another-slug"}

      assert {:ok, %Post{} = post} = Blog.update_post(scope, post, update_attrs, regenerate_slug: true)
      assert post.slug == "another-slug"
    end

    test "regenerate_slug generates a unique slug" do
      valid_attrs = %{description: "some description", slug: "some-slug", title: "some cool title", content: "some content"}
      scope = user_scope_fixture()
      {:ok, _post} = Blog.create_post(scope, valid_attrs)
      post = post_fixture(scope)
      update_attrs = %{title: "some slug"}

      assert {:ok, %Post{} = post} = Blog.update_post(scope, post, update_attrs, regenerate_slug: true)
      assert post.slug != "some-slug"
    end

    test "invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)

      assert_raise MatchError, fn ->
        Blog.update_post(other_scope, post, %{})
      end
    end

    test "invalid data returns error changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Blog.update_post(scope, post, @invalid_attrs)
      assert post == Blog.get_post!(scope, post.id)
    end
  end

  describe "delete_post/2" do
    test "deletes the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:ok, %Post{}} = Blog.delete_post(scope, post)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(scope, post.id) end
    end

    test "invalid scope raises an error" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      assert_raise MatchError, fn -> Blog.delete_post(other_scope, post) end
    end

    test "admin scope can delete" do
      post = user_scope_fixture() |> post_fixture()
      admin_scope = admin_scope_fixture()

      assert {:ok, %Post{}} = Blog.delete_post(admin_scope, post)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(admin_scope, post.id) end
    end
  end

  describe "change_post/2" do
    test "returns a post changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert %Ecto.Changeset{} = Blog.change_post(scope, post)
    end
  end
end
