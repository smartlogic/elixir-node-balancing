defmodule World.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = [
      supervisor(Registry, [:unique, World.ZoneRegistry], [id: World.ZoneRegistry]),
      {World.Supervisor, []},
      {World.ZoneController, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: World.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end
