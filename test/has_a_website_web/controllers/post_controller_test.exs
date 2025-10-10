defmodule HasAWebsiteWeb.PostControllerTest do
  use HasAWebsiteWeb.ConnCase

  import HasAWebsite.BlogFixtures

  @create_attrs %{
    description: "some description",
    title: "some title",
    slug: "some-slug",
    content: "some content"
  }
  @update_attrs %{
    description: "some updated description",
    title: "some updated title",
    slug: "some-updated-slug",
    content: "some updated content"
  }
  @invalid_attrs %{description: nil, title: nil, slug: nil, content: nil}

  setup :register_and_log_in_creator

  describe "index" do
    test "lists all posts", %{conn: conn} do
      conn = get(conn, ~p"/posts")
      assert html_response(conn, 200) =~ "Listing Posts"
    end
  end

  describe "new post" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/posts/new")
      assert html_response(conn, 200) =~ "New Post"
    end
  end

  describe "create post" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/posts", post: @create_attrs)

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/posts/#{slug}"

      conn = get(conn, ~p"/posts/#{slug}")
      assert html_response(conn, 200) =~ "#{@create_attrs.title}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/posts", post: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Post"
    end
  end

  describe "edit post" do
    setup [:create_post]

    test "renders form for editing chosen post", %{conn: conn, post: post} do
      conn = get(conn, ~p"/posts/#{post.slug}/edit")
      assert html_response(conn, 200) =~ "Edit Post"
    end

    test "other users can not access the edit form for others' posts", %{conn: conn, post: post} do
      admin = HasAWebsite.AccountsFixtures.admin_fixture()

      conn =
        log_in_user(
          conn,
          admin,
          conn |> Map.take([:token_authenticated_at]) |> Enum.into([])
        )

      conn = get(conn, ~p"/posts/#{post.slug}/edit")
      assert html_response(conn, 403) =~ "You do not have access"
    end
  end

  describe "update post" do
    setup [:create_post]

    test "redirects when data is valid", %{conn: conn, post: post} do
      conn = put(conn, ~p"/posts/#{post.slug}", post: @update_attrs)
      assert redirected_to(conn) == ~p"/posts/#{@update_attrs.slug}"

      conn = get(conn, ~p"/posts/#{@update_attrs.slug}")
      assert html_response(conn, 200) =~ "#{@update_attrs.title}"

      conn = get(conn, ~p"/posts/#{post.slug}")
      assert html_response(conn, 404) =~ "Page not found"
    end

    test "renders errors when data is invalid", %{conn: conn, post: post} do
      conn = put(conn, ~p"/posts/#{post.slug}", post: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Post"
    end

    test "user can not update someone else's post", %{conn: conn, post: post} do
      creator = HasAWebsite.AccountsFixtures.creator_fixture()

      conn =
        log_in_user(
          conn,
          creator,
          conn |> Map.take([:token_authenticated_at]) |> Enum.into([])
        )

      conn = put(conn, ~p"/posts/#{post.slug}", post: @update_attrs)
      assert html_response(conn, 403) =~ "You do not have access"
    end

    test "admin can not update someone else's post", %{conn: conn, post: post} do
      admin = HasAWebsite.AccountsFixtures.admin_fixture()

      conn =
        log_in_user(
          conn,
          admin,
          conn |> Map.take([:token_authenticated_at]) |> Enum.into([])
        )

      conn = put(conn, ~p"/posts/#{post.slug}", post: @update_attrs)
      assert html_response(conn, 403) =~ "You do not have access"
    end
  end

  describe "delete post" do
    setup [:create_post]

    test "deletes chosen post", %{conn: conn, post: post} do
      conn = delete(conn, ~p"/posts/#{post.slug}")
      assert redirected_to(conn) == ~p"/posts"

      conn = get(conn, ~p"/posts/#{post.slug}")
      assert html_response(conn, 404) =~ "Page not found"
    end

    test "user can not delete someone else's post", %{conn: conn, post: post} do
      creator = HasAWebsite.AccountsFixtures.creator_fixture()

      conn =
        log_in_user(
          conn,
          creator,
          conn |> Map.take([:token_authenticated_at]) |> Enum.into([])
        )

      conn = delete(conn, ~p"/posts/#{post.slug}")
      assert html_response(conn, 403) =~ "You do not have access"
    end

    test "admin can delete someone else's post", %{conn: conn, post: post} do
      admin = HasAWebsite.AccountsFixtures.admin_fixture()

      conn =
        log_in_user(
          conn,
          admin,
          conn |> Map.take([:token_authenticated_at]) |> Enum.into([])
        )

      conn = delete(conn, ~p"/posts/#{post.slug}")
      assert redirected_to(conn) == ~p"/posts"

      conn = get(conn, ~p"/posts/#{post.slug}")
      assert html_response(conn, 404) =~ "Page not found"
    end
  end

  defp create_post(%{scope: scope}) do
    post = post_fixture(scope)

    %{post: post}
  end
end
