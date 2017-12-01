defmodule World.ZoneController do
  @moduledoc """
  GenServer that connects with other zone controllers to spawn zones
  """

  use GenServer
  require Logger

  alias World.Zone

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_zone(pid, zone) do
    GenServer.call(pid, {:start, zone})
  end

  def stop_zones(pid, zones) do
    GenServer.call(pid, {:stop_zones, zones})
  end

  def online_zones(pid) do
    GenServer.call(pid, :online_zones)
  end

  def init(_) do
    :ok = :pg2.create(:zone_controllers)
    :ok = :pg2.join(:zone_controllers, self())
    {:ok, %{zones: []}}
  end

  def handle_call({:start, zone}, _from, state) do
    Logger.info("Starting zone #{zone.id}")
    World.Supervisor.start_child(zone)
    state = %{state | zones: [zone | state.zones]}
    {:reply, node(), state}
  end

  def handle_call(:online_zones, _from, state) do
    {:reply, state.zones, state}
  end

  def handle_call({:stop_zones, zones}, _from, state) do
    Enum.each(zones, fn (zone) ->
      Zone.shutdown(zone.id)
      World.Supervisor.delete_child(zone.id)
    end)

    zone_ids = Enum.map(zones, &(&1.id))
    zones = Enum.reject(state.zones, fn (zone) ->
      zone.id in zone_ids
    end)

    state = %{state | zones: zones}

    {:reply, :ok, state}
  end
end
