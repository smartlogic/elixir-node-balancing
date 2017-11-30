defmodule World.ZoneController do
  @moduledoc """
  GenServer that connects with other zone controllers to spawn zones
  """

  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_zone(pid, zone) do
    GenServer.call(pid, {:start, zone})
  end

  def init(_) do
    :ok = :pg2.create(:zone_controllers)
    :ok = :pg2.join(:zone_controllers, self())
    {:ok, %{}}
  end

  def handle_call({:start, zone}, _from, state) do
    Logger.info("Starting zone #{zone.id}")

    World.Supervisor.start_child(zone)

    {:reply, node(), state}
  end
end
