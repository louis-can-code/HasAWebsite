defmodule HasAWebsiteWeb.Roles do
  @moduledoc """
  Defines role related functions
  """

  alias HasAWebsite.Accounts.User
  alias HasAWebsite.Blog.Post

  @type entity :: struct()
  @type action :: :new | :edit | :delete

  @spec can?(User.t(), entity(), action()) :: :ok | {:error, :unauthorised}
  def can?(%User{role: :admin}, %Post{}, :new), do: :ok
  def can?(%User{role: :creator}, %Post{}, :new), do: :ok

  def can?(%User{role: :admin, id: id}, %Post{author_id: id}, :edit), do: :ok
  def can?(%User{role: :creator, id: id}, %Post{author_id: id}, :edit), do: :ok

  def can?(%User{role: :admin}, %Post{}, :delete), do: :ok
  def can?(%User{role: :creator, id: id}, %Post{author_id: id}, :delete), do: :ok

  def can?(_user, _entity, _action), do: {:error, :unauthorised}
end
