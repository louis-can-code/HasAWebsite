defmodule HasAWebsiteWeb.Plugs.EnsureRole do
  import Plug.Conn

  @moduledoc """
  Ensures a user has a given role before accessing

  ## Example
    If you want to give access to only `:admin` and `:creator` roles:

    `plug EnsureRole, [:admin, :creator]`

    If you want to give acces to only `:admin` role:

    `plug EnsureRole, :admin`
  """
  alias Phoenix.Controller
  alias HasAWebsite.Accounts
  alias HasAWebsite.Accounts.User

  @doc false
  @spec init(any()) :: any()
  def init(default), do: default

  @doc false
  @spec call(Plug.Conn.t(), atom() | [atom()]) :: Plug.Conn.t()
  def call(conn, roles) do
    user_token = get_session(conn, :user_token)

    (user_token &&
      Accounts.get_user_by_session_token(user_token))
    |> has_role?(roles)
    |> maybe_halt(conn)
  end

  defp has_role?(%User{} = user, roles) when is_list(roles),
    do: Enum.any?(roles, &has_role?(user, &1))

  defp has_role?(%User{role: role}, role), do: true
  defp has_role?(_user_or_false, _role), do: false

  defp maybe_halt(true, conn), do: conn
  defp maybe_halt(_, conn) do
    conn
    |> Controller.put_flash(:error, "Unauthorised")
    |> Controller.redirect(to: signed_in_path(conn))
    |> halt()
  end

  defp signed_in_path(_conn), do: "/"
end
