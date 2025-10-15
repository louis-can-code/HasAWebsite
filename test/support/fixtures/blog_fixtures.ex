defmodule HasAWebsite.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HasAWebsite.Blog` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        content: "some content",
        description: "some description",
        title: "some title"
      })

    {:ok, post} = HasAWebsite.Blog.create_post(scope, attrs)
    post
  end

  @doc """
  Generate a comment.
  """
  @spec comment_fixture(
          HasAWebsite.Accounts.Scope.t(),
          HasAWebsite.Blog.Post.t(),
          attrs :: map(),
          replying_to :: HasAWebsite.Blog.Comment.t() | nil
        ) ::
          HasAWebsite.Blog.Comment.t()
  def comment_fixture(scope, post, attrs \\ %{}, replying_to \\ nil) do
    attrs =
      Enum.into(attrs, %{
        content: "some content"
      })

    {:ok, comment} = HasAWebsite.Blog.create_comment(scope, post, attrs, replying_to)

    comment
  end
end
