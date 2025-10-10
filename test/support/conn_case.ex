defmodule HasAWebsiteWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use HasAWebsiteWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint HasAWebsiteWeb.Endpoint

      use HasAWebsiteWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import HasAWebsiteWeb.ConnCase
    end
  end

  setup tags do
    HasAWebsite.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn} = context) do
    user = HasAWebsite.AccountsFixtures.user_fixture()
    scope = HasAWebsite.Accounts.Scope.for_user(user)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, user, opts), user: user, scope: scope}
  end

  @doc """
  Setup helper that registers and logs in users with the creator role.

      setup :register_and_log_in_creator

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_creator(%{conn: conn} = context) do
    creator = HasAWebsite.AccountsFixtures.creator_fixture()
    scope = HasAWebsite.Accounts.Scope.for_user(creator)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, creator, opts), user: creator, scope: scope}
  end

  @doc """
  Setup helper that registers and logs in users with the admin role.

      setup :register_and_log_in_admin

  It stores an updated connection and a registered admin in the
  test context.
  """
  def register_and_log_in_admin(%{conn: conn} = context) do
    admin = HasAWebsite.AccountsFixtures.admin_fixture()
    scope = HasAWebsite.Accounts.Scope.for_user(admin)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, admin, opts), user: admin, scope: scope}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user, opts \\ []) do
    token = HasAWebsite.Accounts.generate_user_session_token(user)

    maybe_set_token_authenticated_at(token, opts[:token_authenticated_at])

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  defp maybe_set_token_authenticated_at(_token, nil), do: nil

  defp maybe_set_token_authenticated_at(token, authenticated_at) do
    HasAWebsite.AccountsFixtures.override_token_authenticated_at(token, authenticated_at)
  end
end
