defmodule HasAWebsiteWeb.UserSessionHTML do
  use HasAWebsiteWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:has_a_website, HasAWebsite.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
