defmodule HasAWebsite.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias HasAWebsite.Repo

  alias HasAWebsite.Blog.Post
  alias HasAWebsite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any post changes.

  The broadcasted messages match the pattern:

    * {:created, %Post{}}
    * {:updated, %Post{}}
    * {:deleted, %Post{}}

  """
  def subscribe_posts(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(HasAWebsite.PubSub, "user:#{key}:posts")
  end

  defp broadcast_post(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(HasAWebsite.PubSub, "user:#{key}:posts", message)
  end

  @doc """
  Returns the list of all posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts() do
    Repo.all(Post)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id) do
    Repo.get_by!(Post, id: id)
  end

  @doc """
  Gets a single post by its slug.

  Returns null if the Post does not exist.

  ## Examples

      iex> get_post_by_slug("post-slug")
      %Post{}

      iex> get_post_by_slug("unknown-slug")
      nil
  """
  def get_post_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Post, slug: slug)
  end

  @doc """
  Checks if a slug already exists.

  ## Examples

      iex> slug_exists?("existing-post")
      true

      iex> slug_exists?("not-an-existing-post")
      false
  """
  def slug_exists?(slug) do
    Repo.exists?(from p in Post, where: p.slug == ^slug)
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(scope, %{field: value})
      {:ok, %Post{}}

      iex> create_post(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(%Scope{} = scope, attrs) do
    with {:ok, post = %Post{}} <-
           %Post{}
           |> Post.create_post_changeset(attrs, scope)
           |> Repo.insert() do
      #TODO: broadcast by user creating post or maybe post tags instead of post updates
      broadcast_post(scope, {:created, post})
      {:ok, post}
    end
  end

  @doc """
  Updates a post.

  Ensure the original post is passed in to the `post` parameter.

  For a list of options, check the Post.update_post_changeset/3 documentation.

  ## Examples

      iex> update_post(scope, post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(scope, post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Scope{} = scope, %Post{} = post, attrs, opts \\ []) do
    true = post.author_id == scope.user.id

    with {:ok, post = %Post{}} <-
           post
           |> Post.update_post_changeset(attrs, opts)
           |> Repo.update() do
      #TODO: broadcasting handling (by user not individual post)
      broadcast_post(scope, {:updated, post})
      {:ok, post}
    end
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(scope, post)
      {:ok, %Post{}}

      iex> delete_post(scope, post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Scope{} = scope, %Post{} = post) do
    #TODO: allow admins to delete posts regardless of author
    true = post.author_id == scope.user.id

    with {:ok, post = %Post{}} <-
           Repo.delete(post) do
      broadcast_post(scope, {:deleted, post})
      {:ok, post}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(scope, post)
      %Ecto.Changeset{data: %Post{}}

  """
  #TODO: figure out what is happening here
  def change_post(%Scope{} = scope, %Post{} = post, attrs \\ %{}) do
    true = post.author_id == scope.user.id

    Post.changeset(post, attrs, scope)
  end
end
