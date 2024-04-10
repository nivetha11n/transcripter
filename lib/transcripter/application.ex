defmodule Transcripter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  @folder_path "/Users/nivethanagarajan/audiostream"

  use Application

  @impl true
  def start(_type, _args) do

    Nx.default_backend(EXLA.Backend)

    children = [
      TranscripterWeb.Telemetry,
      Transcripter.Repo,
      {DNSCluster, query: Application.get_env(:transcripter, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Transcripter.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Transcripter.Finch},
      # Start a worker by calling: Transcripter.Worker.start_link(arg)
      # {Transcripter.Worker, arg},
      # Start to serve requests, typically the last entry
     # %{
      #  id: FileSystem,  # Unique identifier for the child spec
      #  start: {FileSystem, :start_link, [dirs: [@folder_path], name: :my_monitor_name]},
      #  type: :worker,  # Assuming FileSystem acts as a worker
       # restart: :permanent,  # If it should always be restarted on termination
       # shutdown: 5000  # Graceful shutdown timeout in milliseconds
      #},
      TranscripterWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Transcripter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TranscripterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
