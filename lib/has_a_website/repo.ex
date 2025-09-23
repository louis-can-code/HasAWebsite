defmodule HasAWebsite.Repo do
  use Ecto.Repo,
    otp_app: :has_a_website,
    adapter: Ecto.Adapters.Postgres
end
