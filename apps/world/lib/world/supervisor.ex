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
    child_spec = worker(Zone, [zone], id: zone.id, restart: :transient)
    Supervisor.start_child(__MODULE__, child_spec)
  end

  def delete_child(zone_id), do: Supervisor.delete_child(__MODULE__, zone_id)

  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end
