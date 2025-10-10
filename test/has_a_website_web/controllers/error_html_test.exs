defmodule HasAWebsiteWeb.ErrorHTMLTest do
  use HasAWebsiteWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 401.html" do
    assert render_to_string(HasAWebsiteWeb.ErrorHTML, "401", "html", []) =~
             "You are not logged in"
  end

  test "renders 403.html" do
    assert render_to_string(HasAWebsiteWeb.ErrorHTML, "403", "html", []) =~
             "You do not have access"
  end

  test "renders 404.html" do
    assert render_to_string(HasAWebsiteWeb.ErrorHTML, "404", "html", []) =~ "Page not found"
  end

  test "renders 500.html" do
    assert render_to_string(HasAWebsiteWeb.ErrorHTML, "500", "html", []) =~
             "Internal Server Error"
  end
end
