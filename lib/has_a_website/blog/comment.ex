defmodule HasAWebsite.Blog.Comment do
  use Ecto.Schema

  import Ecto.Changeset

  alias HasAWebsite.Accounts.User
  alias HasAWebsite.Blog.Post

  @type t :: %__MODULE__{
          id: integer(),
          content: String.t(),

          # Foreign keys
          user_id: integer(),
          post_id: integer(),
          replying_to_id: integer() | nil,

          # Associations
          user: User.t() | Ecto.Association.NotLoaded.t(),
          post: Post.t() | Ecto.Association.NotLoaded.t(),
          replying_to: __MODULE__.t() | Ecto.Association.NotLoaded.t() | nil,
          replies: [__MODULE__.t()] | Ecto.Association.NotLoaded.t(),

          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type new_t :: %__MODULE__{
          id: integer() | nil,
          content: String.t() | nil,

          # Foreign keys
          user_id: integer() | nil,
          post_id: integer() | nil,
          replying_to_id: integer() | nil,

          # Associations
          user: User.t() | Ecto.Association.NotLoaded.t() | nil,
          post: Post.t() | Ecto.Association.NotLoaded.t() | nil,
          replying_to: __MODULE__.t() | Ecto.Association.NotLoaded.t() | nil,
          replies: [__MODULE__.t()] | Ecto.Association.NotLoaded.t() | nil,

          # Timestamps
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "comments" do
    field :content, :string

    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :replying_to, __MODULE__

    has_many :replies, __MODULE__, foreign_key: :replying_to_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Wraps an inputted comment in a changeset
  """
  @spec changeset(__MODULE__.new_t(), map()) :: Ecto.Changeset.t()
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content])
  end

  @doc """
  A comment changeset for creating a comment
  """
  @spec create_comment_changeset(map(), integer(), integer(), replying_to_id :: integer() | nil) ::
          Ecto.Changeset.t()
  def create_comment_changeset(attrs, user_id, post_id, replying_to_id \\ nil) do
    %__MODULE__{}
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> validate_length(:content, min: 1, max: 1024)
    |> put_change(:user_id, user_id)
    |> put_change(:post_id, post_id)
    |> put_change(:replying_to_id, replying_to_id)
    |> assoc_constraint(:user)
    |> assoc_constraint(:post)
    |> assoc_constraint(:replying_to)
  end

  @doc """
  A comment changeset for updating a comment
  """
  @spec update_comment_changeset(__MODULE__.new_t(), map()) :: Ecto.Changeset.t()
  def update_comment_changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content])
    |> validate_not_null([:content])
    |> validate_length(:content, min: 1, max: 1024)
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
