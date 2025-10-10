defmodule HasAWebsiteWeb.FallbackController do
  use HasAWebsiteWeb, :controller

  def call(conn, {:error, :unauthorised}) do
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
      |> put_status(:forbidden)
      |> put_view(HasAWebsiteWeb.ErrorHTML)
      |> render(:"403")
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(HasAWebsiteWeb.ErrorHTML)
      |> render(:"401")
    end
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> put_view(HasAWebsiteWeb.ErrorHTML)
    |> render(:"404")
  end
end
