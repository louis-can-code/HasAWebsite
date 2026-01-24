defmodule HasAWebsite.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false

  alias HasAWebsite.Repo

  alias HasAWebsite.Blog.Post
  alias HasAWebsite.Blog.Comment
  alias HasAWebsite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any post changes.

  The broadcasted messages match the pattern:

    * {:created, %Post{}}
    * {:updated, %Post{}}
    * {:deleted, %Post{}}

  """
  @spec subscribe_posts(Scope.t()) :: :ok | {:error, {:already_registered, pid()}}
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

  ## Options
    * `preloads` - takes a list of atoms:
      - `:author` to preload the associated author

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

      iex> list_posts([:author])
      [%Post{author: %User{}}, ...]

  """
  @spec list_posts(opts :: Keyword.t()) :: [Post.t()]
  def list_posts(opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Post
    |> order_by(desc: :published_at)
    |> preload(^preloads)
    |> Repo.all()
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
  @spec get_post!(integer()) :: Post.t()
  def get_post!(id) do
    Repo.get_by!(Post, id: id)
  end

  @doc """
  Gets a single post by its slug.

  Returns nil if the Post does not exist.

  ## Options
    * `:preloads` - takes a list of atoms:
      - `:author` to preload the associated author
      - `comments: comment_limit` to preload up to `comment_limit` associated comments
        (defaults to 10 comments if no limit is given)


  ## Examples

      iex> get_post_by_slug!("post-slug")
      %Post{}

      iex> get_post_by_slug!("post-slug", preloads: [:author, comments: 10])
      %Post{author: %User{}, comments: [%Comments{}]}

      iex> get_post_by_slug!("unknown-slug")
      nil
  """
  @spec get_post_by_slug(String.t(), opts :: Keyword.t()) :: Post.t() | {:error, :not_found}
  def get_post_by_slug(slug, opts \\ []) when is_binary(slug) do
    preloads = Keyword.get(opts, :preloads, [])

    preloads =
      Enum.reduce(preloads, [], fn
        :author, acc -> [:author | acc]
        :comments, acc -> [{:comments, top_comments_query(10)} | acc]
        {:comments, limit}, acc -> [{:comments, top_comments_query(limit)} | acc]
        _, acc -> acc
      end)

    post =
      Post
      |> preload(^preloads)
      |> Repo.get_by(slug: slug)

    if post, do: post, else: {:error, :not_found}
  end

  defp top_comments_query(limit) do
    from c in Comment,
      where: is_nil(c.replying_to_id),
      order_by: [desc: c.inserted_at],
      limit: ^limit,
      preload: [:user, replies: ^top_reply_query()]
  end

  # TODO: add upvote/like system, and make requirement for top reply
  defp top_reply_query() do
    from c in Comment,
      order_by: [desc: c.inserted_at],
      limit: 1,
      preload: [:user]
  end

  @doc """
  Checks if a slug already exists.

  ## Examples

      iex> slug_exists?("existing-post")
      true

      iex> slug_exists?("not-an-existing-post")
      false
  """
  @spec slug_exists?(String.t()) :: boolean()
  def slug_exists?(slug) do
    Repo.exists?(from p in Post, where: p.slug == ^slug)
  end

  @doc """
  Generates a unique slug usign the input

  ## Examples

      iex> generate_slug("Some Title")
      some-title

      iex> generate_slug("existing-slug")
      existing-slug-2
  ##
  """
  @spec generate_slug(String.t()) :: String.t()
  def generate_slug(title) do
    title
    |> title_to_slug()
    |> unique_slug()
  end

  defp title_to_slug(title) do
    title
    |> String.downcase()
    |> String.trim()
    |> String.trim("-")
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/[\s|-]+/, "-")
  end

  # if the slug is taken
  # query Post for a list of number iterations of the slug
  defp unique_slug(base_slug) do
    pattern = "^#{base_slug}-(\\d+)$"

    if slug_exists?(base_slug) do
      from(p in Post,
        where: fragment("? ~ ?", p.slug, ^pattern),
        select: fragment("substring(? FROM ?)::integer", p.slug, ^pattern)
      )
      |> Repo.all()
      |> find_next_available_slug(base_slug)
    else
      base_slug
    end
  end

  # find the smallest number for which a slug does not yet exist
  defp find_next_available_slug([], slug), do: "#{slug}-2"

  defp find_next_available_slug(number_list, slug) do
    number_set = MapSet.new(number_list)

    num =
      Stream.iterate(2, &(&1 + 1))
      |> Enum.find(&(!MapSet.member?(number_set, &1)))

    "#{slug}-#{num}"
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(scope, %{field: value})
      {:ok, %Post{}}

      iex> create_post(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_post(Scope.t(), map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def create_post(%Scope{} = scope, attrs) do
    attrs =
      with true <- !Map.has_key?(attrs, :slug),
           true <- Map.has_key?(attrs, :title) do
        Map.put(attrs, :slug, generate_slug(attrs.title))
      else
        _ -> attrs
      end

    with {:ok, post = %Post{}} <-
           attrs
           |> Post.create_post_changeset(scope.user.id)
           |> Repo.insert() do
      # TODO: broadcast by user creating post
      broadcast_post(scope, {:created, post})
      {:ok, post}
    end
  end

  @doc """
  Updates a post.

  Ensure the original post is passed in to the `post` parameter,
  and that it is the default value on the update form.

  ## Options
    * `:regenerate_slug` - Set to `true` if you want to regenerate
      the URL slug (generated from the title)

  ## Examples

      iex> update_post(scope, post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(scope, post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_post(Scope.t(), Post.t(), map(), opts :: Keyword.t()) ::
          {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def update_post(%Scope{} = scope, %Post{} = post, attrs, opts \\ []) do
    true = post.author_id == scope.user.id

    attrs = maybe_update_slug(post, attrs, opts)

    with {:ok, post = %Post{}} <-
           post
           |> Post.update_post_changeset(attrs)
           |> Repo.update() do
      # TODO: look into broadcasting
      broadcast_post(scope, {:updated, post})
      {:ok, post}
    end
  end

  # generates a slug if:
  # - no new slug was provided
  # - a new title was provided
  # - regenerate_slug option was set to true
  # - the new slug is not equivalent to the old one
  defp maybe_update_slug(post, attrs, opts) do
    with true <- !Map.has_key?(attrs, :slug),
         true <- Map.has_key?(attrs, :title),
         true <- Keyword.get(opts, :regenerate_slug, false),
         true <- new_title_needs_new_slug?(post.slug, attrs.title) do
      Map.put(attrs, :slug, generate_slug(attrs.title))
    else
      _ -> attrs
    end
  end

  # Checks if the new slug would be of the same form as the old slug
  defp new_title_needs_new_slug?(old_slug, new_title) do
    base_slug = title_to_slug(new_title)
    pattern = ~r/^#{base_slug}(-\d+)?$/

    !Regex.match?(pattern, old_slug)
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(scope, post)
      {:ok, %Post{}}

      iex> delete_post(scope, post)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_post(Scope.t(), Post.t()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def delete_post(%Scope{} = scope, %Post{} = post) do
    true = post.author_id == scope.user.id || verify_admin?(scope.user.role)

    with {:ok, post = %Post{}} <-
           Repo.delete(post) do
      broadcast_post(scope, {:deleted, post})
      {:ok, post}
    end
  end

  defp verify_admin?(:admin), do: true
  defp verify_admin?(_), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(scope, post)
      %Ecto.Changeset{data: %Post{}}

  """
  @spec change_post(Scope.t(), Post.new_t(), attrs :: map()) :: Ecto.Changeset.t()
  def change_post(%Scope{} = scope, %Post{} = post, attrs \\ %{}) do
    true = post.author_id == scope.user.id

    Post.changeset(post, attrs)
  end

  @doc """
  Returns the list of comments on a post.

  ## Examples

      iex> list_comments(123)
      [%Comment{}, ...]

  """
  # TODO: Paginate
  @spec list_comments(integer()) :: [Comment.t()]
  def list_comments(post_id) do
    Repo.all_by(Comment, post_id: post_id)
  end

  @doc """
  Returns the list of replies to a comment on a post

  ## Example

      iex> list_replies(12, 11)
      [%Comment{}, ...]
  """
  # TODO: Paginate
  @spec list_replies(integer(), integer()) :: [Comment.t()]
  def list_replies(post_id, comment_id) do
    Repo.all_by(Comment, post_id: post_id, replying_to_id: comment_id)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_comment!(integer()) :: Comment.t()
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment. Optional replying_to field for when the comment
  is replying to another comment

  ## Examples

      iex> create_comment(scope, post, %{field: value})
      {:ok, %Comment{}}

      iex> create_comment(scope, post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_comment(Scope.t(), Post.t(), map(), replying_to :: Comment.t() | nil) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def create_comment(%Scope{} = scope, %Post{} = post, attrs, replying_to \\ nil) do
    attrs
    |> Comment.create_comment_changeset(
      scope.user.id,
      post.id,
      if(replying_to, do: replying_to.id, else: nil)
    )
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_comment(Scope.t(), Comment.new_t(), map()) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def update_comment(scope, %Comment{} = comment, attrs) do
    true = comment.user_id == scope.user.id

    comment
    |> Comment.update_comment_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_comment(Scope.t(), Comment.t()) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def delete_comment(scope, %Comment{} = comment) do
    true = scope.user.id == comment.user_id || scope.user.role == :admin

    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  @spec change_comment(Comment.new_t(), attrs :: map()) :: Ecto.Changeset.t()
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end
end
