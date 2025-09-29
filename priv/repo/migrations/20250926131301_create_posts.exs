defmodule HasAWebsite.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :citext, null: false
      add :slug, :string, null: false
      add :description, :text, null: false
      add :content, :text, null: false
      add :published_at, :utc_datetime, null: false
      add :last_updated_at, :utc_datetime
      add :author_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:author_id])
    create unique_index(:posts, [:slug])
  end
end
