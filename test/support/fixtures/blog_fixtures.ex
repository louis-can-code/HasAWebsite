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
        published_at: ~U[2025-09-25 13:13:00Z],
        slug: "some slug",
        title: "some title"
      })

    {:ok, post} = HasAWebsite.Blog.create_post(scope, attrs)
    post
  end
end
