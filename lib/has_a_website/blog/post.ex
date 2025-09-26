defmodule HasAWebsite.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :content, :string
    field :published_at, :utc_datetime

    belongs_to :author, HasAWebsite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs, user_scope) do
    post
    |> cast(attrs, [:title, :slug, :description, :content, :published_at])
    |> validate_required([:title, :slug, :description, :content, :published_at])
    |> put_change(:user_id, user_scope.user.id)
  end
end
