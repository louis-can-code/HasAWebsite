defmodule HasAWebsiteWeb.PageController do
  use HasAWebsiteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
