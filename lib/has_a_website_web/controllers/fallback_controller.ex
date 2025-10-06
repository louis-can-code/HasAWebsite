defmodule HasAWebsiteWeb.FallbackController do
  use HasAWebsiteWeb, :controller

  def call(conn, {:error, :unauthorised}) do
    conn
    |> put_flash(:error, "Unauthorised access")
    |> redirect(to: ~p"/posts")
  end

  def call(conn, nil) do
    conn
    |> put_flash(:error, "Post not found")
    |> redirect(to: ~p"/posts")
  end
end
