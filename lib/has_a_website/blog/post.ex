defmodule HasAWebsite.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :content, :string
    field :published_at, :utc_datetime
    field :last_updated_at, :utc_datetime

    belongs_to :author, HasAWebsite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default post changeset
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :description, :content])
  end

  @doc """
  A changeset for creating a post

  If no slug is provided, a unique slug will be generated
  """
  def create_post_changeset(post, attrs, user_scope) do
    post
    |> cast(attrs, [:title, :slug, :description, :content])
    |> validate_required([:title, :slug, :description, :content])
    |> validate_title()
    |> put_change(:author_id, user_scope.user.id)
    |> put_change(:published_at, DateTime.utc_now(:second))
    |> validate_slug()
  end

  defp validate_title(changeset) do
    changeset
    |> validate_format(:title, ~r/^[^\s].*[^\s]$/, message: "can not start or end with whitespace")
    |> validate_length(:title, min: 1, max: 86)
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "can only contain numbers, lowercase letters, and hyphens")
    |> validate_format(:slug, ~r/^(?!.*--).*$/,
      message: "can not contain consecutive hyphens")
    |> validate_format(:slug, ~r/^[^-].*[^-]$/,
      message: "can not start/end with a hyphen")
    |> validate_length(:slug, max: 86)
    |> unsafe_validate_unique(:slug, HasAWebsite.Repo)
    |> unique_constraint(:slug)
  end

  @doc """
  A changeset for updating a post.

  Ensure the original post is passed in with the update
  """
  def update_post_changeset(post, attrs) do
    changeset =
      post
      |> cast(attrs, [:title, :slug, :description, :content])
      |> validate_not_null([:title, :slug, :description, :content])
      |> validate_title()
      |> validate_length(:description, min: 1, max: 256)
      |> put_change(:last_updated_at, DateTime.utc_now(:second))

    if changeset.data.slug != get_field(changeset, :slug) do
      validate_slug(changeset)
    else
      changeset
    end
  end

  defp validate_not_null(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, set ->
      if get_change(set, field, :no_change) == nil do
        add_error(set, field, "can not be null")
      else
        set
      end
    end)
  end
end
