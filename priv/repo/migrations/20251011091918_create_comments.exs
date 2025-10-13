defmodule HasAWebsite.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :post_id, references(:posts, on_delete: :nothing), null: false
      add :replying_to_id, references(:comments, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:user_id])
    create index(:comments, [:post_id])
    create index(:comments, [:replying_to_id])
  end
end
