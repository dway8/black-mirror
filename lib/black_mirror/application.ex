defmodule BlackMirror.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BlackMirrorWeb.Telemetry,
      # Start the Ecto repository
      BlackMirror.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: BlackMirror.PubSub},
      # Start Finch
      {Finch, name: BlackMirror.Finch},
      # Start the Endpoint (http/https)
      BlackMirrorWeb.Endpoint
      # Start a worker by calling: BlackMirror.Worker.start_link(arg)
      # {BlackMirror.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BlackMirror.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlackMirrorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
