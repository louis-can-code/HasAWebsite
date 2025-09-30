defmodule HasAWebsite.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :content, :string
    field :published_at, :utc_datetime
    field :last_update_at, :utc_datetime

    belongs_to :author, HasAWebsite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default post changeset
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :description, :content])
    |> validate_required([:title, :slug, :description, :content])
  end

  @doc """
  A changeset for creating a post

  If no slug is provided, a unique slug will be generated
  """
  def create_post_changeset(post, %{slug: _slug} = attrs, user_scope) do
    post
    |> cast(attrs, [:title, :slug, :description, :content])
    |> validate_required([:title, :slug, :description, :content])
    |> validate_title()
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:published_at, DateTime.utc_now(:second))
    |> unsafe_validate_unique(:slug, Post)
    |> unique_constraint(:slug)
  end

  def create_post_changeset(post, attrs, user_scope) do
    post
    |> cast(attrs, [:title, :description, :content])
    |> validate_required([:title, :description, :content])
    |> validate_title()
    |> validate_length(:description, max: 256)
    |> slug_generator()
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:published_at, DateTime.utc_now(:second))
  end

  defp validate_title(changeset) do
    changeset
    |> validate_format(:title, ~r/^[^\S].*[^\S]$/, message: "can not start or end with whitespace")
    |> validate_length(:title, min: 1, max: 86)
  end

  defp slug_generator(changeset) do
    changeset
    |> get_field(:title)
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.replace(~r/\s+/, "-")
    |> unique_slug(changeset)
  end

  defp unique_slug(slug, changeset, attempt \\ 1) do
    candidate_slug =
      if attempt == 1 do
        slug
      else
        "#{slug}-#{attempt}"
      end

    if HasAWebsite.Blog.slug_exists?(candidate_slug) do
      unique_slug(slug, changeset, attempt + 1)
    else
      put_change(changeset, :slug, candidate_slug)
    end
  end

  @doc """
  A changeset for updating a post.

  Ensure the original post is passed in with the update

  ## Options
    * `:regenerate_slug` - Set to true if you would
      like title changes to be reflected in the url
      slug.
  """
  def update_post_changeset(post, attrs, opts \\ []) do
    post
    |> cast(attrs, [:title, :slug, :description, :content])
    |> maybe_update_slug(opts)
    |> validate_title()
    |> validate_length(:description, max: 256)
    |> put_change(:last_updated_at, DateTime.utc_now(:second))
  end

  defp maybe_update_slug(changeset, opts) do
    original_slug = changeset.data.slug
    new_slug = get_change(changeset, :slug)
    new_title = get_change(changeset, :title)

    case {new_slug, new_title, Keyword.get(opts, :regenerate_slug)} do
      {nil, title, true} when not is_nil(title) ->
        slug_generator(changeset)

      {slug, _, _} when slug != original_slug ->
        changeset
        |> unsafe_validate_unique(:slug, Post)
        |> unique_constraint(:slug)

      _ ->
        changeset
    end
  end
end
