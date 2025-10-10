defmodule HasAWebsiteWeb.Roles do
  @moduledoc """
  Defines role related functions
  """

  alias HasAWebsite.Accounts.User
  alias HasAWebsite.Blog.Post

  @type entity :: struct()
  @type action :: :new | :create | :edit | :delete | :update

  @spec authorise(User.t(), entity(), action()) :: :ok | {:error, :unauthorised}
  def authorise(%User{role: role}, %Post{}, action)
      when role in [:creator, :admin] and action in [:new, :create],
      do: :ok

  def authorise(%User{role: role, id: id}, %Post{author_id: id}, action)
      when role in [:creator, :admin] and action in [:edit, :update],
      do: :ok

  def authorise(%User{role: :admin}, %Post{}, :delete), do: :ok
  def authorise(%User{role: :creator, id: id}, %Post{author_id: id}, :delete), do: :ok

  def authorise(_user, _entity, _action), do: {:error, :unauthorised}
end
