defmodule HasAWebsite.BlogTest do
  use HasAWebsite.DataCase

  alias HasAWebsite.Blog

  alias HasAWebsite.Blog.Post
  alias HasAWebsite.Blog.Comment

  import HasAWebsite.AccountsFixtures,
    only: [user_scope_fixture: 0, admin_scope_fixture: 0, creator_fixture: 0]

  import HasAWebsite.BlogFixtures

  @invalid_attrs %{description: nil, title: nil, slug: nil, content: nil}

  describe "list_post/1" do
    test "returns all posts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      other_post = post_fixture(other_scope)

      posts = Blog.list_posts()
      assert post in posts && other_post in posts
    end

    test "returns all post, with author details" do
      # TODO: this test
    end
  end

  describe "get_post!/1" do
    test "returns the post with given id" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert Blog.get_post!(post.id) == post
    end
  end

  describe "get_post_by_slug" do
    test "returns the post with given slug" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert Blog.get_post_by_slug(post.slug) == post
    end

    test "returns the post and author details" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      get_post = Blog.get_post_by_slug(post.slug, preloads: [:author])
      assert get_post.author.id == scope.user.id
    end

    # TODO: test with comment preloads

    test "does not return non-existing post" do
      assert {:error, :not_found} == Blog.get_post_by_slug("unknown-slug")
    end
  end

  describe "create_post/2" do
    test "valid data creates a post" do
      valid_attrs = %{
        description: "some description",
        title: "some cool title",
        slug: "some-slug",
        content: "some content"
      }

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
      valid_attrs = %{
        description: "some description",
        title: "some cool title",
        content: "some content"
      }

      scope = user_scope_fixture()

      assert {:ok, %Post{} = post} = Blog.create_post(scope, valid_attrs)
      assert post.description == "some description"
      assert post.title == "some cool title"
      assert post.slug == "some-cool-title"
      assert post.content == "some content"
      assert !is_nil(post.published_at)
      assert post.author_id == scope.user.id
    end

    test "an already existing slug returns an error" do
      valid_attrs = %{
        description: "some description",
        slug: "some-slug",
        title: "some cool title",
        content: "some content"
      }

      scope = user_scope_fixture()
      {:ok, _post} = Blog.create_post(scope, valid_attrs)

      assert {:error, %Ecto.Changeset{}} =
               Blog.create_post(scope, %{
                 description: "some description",
                 slug: "some-slug",
                 title: "test title",
                 content: "some content"
               })
    end

    test "auto-generated slug generates a unique slug" do
      scope = user_scope_fixture()

      {:ok, _post} =
        Blog.create_post(scope, %{
          description: "some description",
          slug: "test",
          title: "test title",
          content: "some content"
        })

      {:ok, post} =
        Blog.create_post(scope, %{
          description: "another description",
          title: "test",
          content: "more content"
        })

      assert post.slug != "test"
    end
  end

  describe "update_post/3" do
    test "valid data updates the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)

      update_attrs = %{
        description: "some updated description",
        slug: "new-slug",
        title: "some updated title",
        content: "some updated content"
      }

      assert {:ok, %Post{} = post} = Blog.update_post(scope, post, update_attrs)
      assert post.description == "some updated description"
      assert post.title == "some updated title"
      assert post.slug == "new-slug"
      assert post.content == "some updated content"
      assert !is_nil(post.published_at)
      assert !is_nil(post.last_updated_at)
    end

    test "updated slug maintains unique constraint" do
      valid_attrs = %{
        description: "some description",
        slug: "some-slug",
        title: "some cool title",
        content: "some content"
      }

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

      assert {:ok, %Post{} = post} =
               Blog.update_post(scope, post, update_attrs, regenerate_slug: true)

      assert post.slug == "new-title"
    end

    test "regenerate_slug does not regenerate if a new slug is provided" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      update_attrs = %{title: "new title", slug: "another-slug"}

      assert {:ok, %Post{} = post} =
               Blog.update_post(scope, post, update_attrs, regenerate_slug: true)

      assert post.slug == "another-slug"
    end

    test "regenerate_slug generates a unique slug" do
      valid_attrs = %{
        description: "some description",
        slug: "some-slug",
        title: "some cool title",
        content: "some content"
      }

      scope = user_scope_fixture()
      {:ok, _post} = Blog.create_post(scope, valid_attrs)
      post = post_fixture(scope)
      update_attrs = %{title: "some slug"}

      assert {:ok, %Post{} = post} =
               Blog.update_post(scope, post, update_attrs, regenerate_slug: true)

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
      assert post == Blog.get_post!(post.id)
    end
  end

  describe "delete_post/2" do
    test "deletes the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:ok, %Post{}} = Blog.delete_post(scope, post)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(post.id) end
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
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(post.id) end
    end
  end

  describe "change_post/2" do
    test "returns a post changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert %Ecto.Changeset{} = Blog.change_post(scope, post)
    end
  end

  @invalid_attrs %{content: nil}

  setup do
    scope =
      creator_fixture()
      |> HasAWebsite.Accounts.Scope.for_user()

    post = post_fixture(scope)

    %{scope: scope, post: post}
  end

  describe "list_comments/0" do
    test "returns all comments", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      assert Blog.list_comments(post.id) == [comment]
    end
  end

  describe "list_replies/0" do
    test "returns all comment replies", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      reply = comment_fixture(scope, post, %{}, comment)
      assert Blog.list_replies(post.id, comment.id) == [reply]
    end
  end

  describe "get_comment!/1" do
    test "returns the comment with given id", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      assert Blog.get_comment!(comment.id) == comment
    end
  end

  describe "create_comment/1" do
    test "valid data creates a comment", %{scope: scope, post: post} do
      valid_attrs = %{content: "some content"}

      assert {:ok, %Comment{} = comment} = Blog.create_comment(scope, post, valid_attrs)
      assert comment.content == "some content"
    end

    test "invalid data returns error changeset", %{scope: scope, post: post} do
      assert {:error, %Ecto.Changeset{}} = Blog.create_comment(scope, post, @invalid_attrs)
    end
  end

  describe "update_comment/2" do
    test "valid data updates the comment", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Comment{} = comment} = Blog.update_comment(scope, comment, update_attrs)
      assert comment.content == "some updated content"
    end

    test "invalid data returns error changeset", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      assert {:error, %Ecto.Changeset{}} = Blog.update_comment(scope, comment, @invalid_attrs)
      assert comment == Blog.get_comment!(comment.id)
    end
  end

  describe "delete_comment/1" do
    test "deletes the comment", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      assert {:ok, %Comment{}} = Blog.delete_comment(scope, comment)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_comment!(comment.id) end
    end
  end

  describe "change_comment/1" do
    test "returns a comment changeset", %{scope: scope, post: post} do
      comment = comment_fixture(scope, post)
      assert %Ecto.Changeset{} = Blog.change_comment(comment)
    end
  end
end
