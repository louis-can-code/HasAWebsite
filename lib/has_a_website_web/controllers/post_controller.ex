defmodule HasAWebsiteWeb.PostController do
  use HasAWebsiteWeb, :controller

  alias HasAWebsite.Blog
  alias HasAWebsite.Blog.Post
  alias HasAWebsiteWeb.Roles

  action_fallback HasAWebsiteWeb.FallbackController

  def index(conn, _params) do
    posts = Blog.list_posts(preloads: [:author])
    render(conn, :index, posts: posts)
  end

  def new(conn, _params) do
    with :ok <- Roles.can?(conn.assigns.current_scope.user, %Post{}, :new) do
      changeset =
        Blog.change_post(conn.assigns.current_scope, %Post{
          author_id: conn.assigns.current_scope.user.id
        })

      render(conn, :new, changeset: changeset)
    end
  end

  def create(conn, %{"post" => post_params}) do
    case Blog.create_post(conn.assigns.current_scope, post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"slug" => slug}) do
    with post when not is_nil(post) <- Blog.get_post_by_slug(slug, preloads: [:author]),
      do: render(conn, :show, post: post)
  end

  def edit(conn, %{"slug" => slug}) do
    with post when not is_nil(post) <- Blog.get_post_by_slug(slug, preloads: [:author]),
      :ok <- Roles.can?(conn.assigns.current_scope.user, post, :edit) do

      changeset = Blog.change_post(conn.assigns.current_scope, post)
      render(conn, :edit, post: post, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Blog.get_post!(id)

    case Blog.update_post(conn.assigns.current_scope, post, post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"slug" => slug}) do
    with post when not is_nil(post) <- Blog.get_post_by_slug(slug),
      :ok <- Roles.can?(conn.assigns.current_scope.user, post, :delete) do

      {:ok, _post} = Blog.delete_post(conn.assigns.current_scope, post)

      conn
      |> put_flash(:info, "Post deleted successfully.")
      |> redirect(to: ~p"/posts")
    end
  end
end
