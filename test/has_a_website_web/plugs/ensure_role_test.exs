defmodule HasAWebsiteWeb.EnsureRoleTest do
  use HasAWebsiteWeb.ConnCase

  setup [:register_and_log_in_user]

  describe "Ensure Role plug" do
    test "unauthorised users can not access restricted routes", %{conn: conn} do
      conn = get(conn, ~p"/posts/new")
      assert html_response(conn, 403) =~ "You do not have access"
    end
  end
end
