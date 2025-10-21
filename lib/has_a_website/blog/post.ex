defmodule HasAWebsite.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          # Required fields
          id: integer(),
          title: String.t(),
          slug: String.t(),
          description: String.t(),
          content: String.t(),
          published_at: DateTime.t(),
          last_updated_at: DateTime.t(),
          author_id: integer(),

          # Associations
          author: HasAWebsite.Accounts.User.t() | Ecto.Association.NotLoaded.t(),
          comments: [HasAWebsite.Blog.Comment.t()] | Ecto.Association.NotLoaded.t(),

          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }
  @typedoc """
  Post type for creating posts
  """
  @type new_t :: %__MODULE__{
          # Required fields
          id: integer() | nil,
          title: String.t() | nil,
          slug: String.t() | nil,
          description: String.t() | nil,
          content: String.t() | nil,
          published_at: DateTime.t() | nil,
          last_updated_at: DateTime.t() | nil,
          author_id: integer() | nil,

          # Associations
          author: HasAWebsite.Accounts.User.t() | Ecto.Association.NotLoaded.t() | nil,
          comments: [HasAWebsite.Blog.Comment.t()] | Ecto.Association.NotLoaded.t() | nil,

          # Timestamps
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :content, :string
    field :published_at, :utc_datetime
    field :last_updated_at, :utc_datetime

    belongs_to :author, HasAWebsite.Accounts.User

    has_many :comments, HasAWebsite.Blog.Comment

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default post changeset
  """
  @spec changeset(__MODULE__.new_t(), map()) :: Ecto.Changeset.t()
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :description, :content])
  end

  @doc """
  A changeset for creating a post

  If no slug is provided, a unique slug will be generated
  """
  @spec create_post_changeset(map(), integer()) :: Ecto.Changeset.t()
  def create_post_changeset(attrs, author_id) do
    %__MODULE__{}
    |> cast(attrs, [:title, :slug, :description, :content])
    |> validate_required([:title, :slug, :description, :content])
    |> validate_title()
    |> put_change(:author_id, author_id)
    |> put_change(:published_at, DateTime.utc_now(:second))
    |> validate_slug()
  end

  defp validate_title(changeset) do
    changeset
    |> validate_format(:title, ~r/^[^\s].*[^\s]$/,
      message: "can not start or end with whitespace"
    )
    |> validate_length(:title, min: 1, max: 86)
  end

  @reserved_slugs ~w(
    new index create delete show edit settings login log-in
    logout log-out dashboard register
    )
  defp validate_slug(changeset) do
    changeset
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "can only contain numbers, lowercase letters, and hyphens"
    )
    |> validate_format(:slug, ~r/^(?!.*--).*$/, message: "can not contain consecutive hyphens")
    |> validate_format(:slug, ~r/^[^-].*[^-]$/, message: "can not start/end with a hyphen")
    |> validate_exclusion(:slug, @reserved_slugs, message: "slug is reserved")
    |> validate_length(:slug, max: 86)
    |> unsafe_validate_unique(:slug, HasAWebsite.Repo)
    |> unique_constraint(:slug)
  end

  @doc """
  A changeset for updating a post.

  Ensure the original post is passed in with the update
  """
  @spec update_post_changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
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
