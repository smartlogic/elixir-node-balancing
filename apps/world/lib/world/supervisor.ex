defmodule World.Supervisor do
  @moduledoc """
  Main supervisor for zones underneath
  """

  use Supervisor

  alias World.Zone

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(zone) do
    child_spec = worker(Zone, [zone], id: zone.id, restart: :permanent)
    Supervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end
