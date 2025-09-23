defmodule HasAWebsite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HasAWebsiteWeb.Telemetry,
      HasAWebsite.Repo,
      {DNSCluster, query: Application.get_env(:has_a_website, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HasAWebsite.PubSub},
      # Start a worker by calling: HasAWebsite.Worker.start_link(arg)
      # {HasAWebsite.Worker, arg},
      # Start to serve requests, typically the last entry
      HasAWebsiteWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HasAWebsite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HasAWebsiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
