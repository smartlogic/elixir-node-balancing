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
    :ok = :pg2.create(:zone_master)
    :ok = :pg2.create(:zone_controllers)
    :ok = :pg2.join(:zone_controllers, self())
    :ok = :net_kernel.monitor_nodes(true)
    {:ok, %{zones: []}}
  end

  def handle_call({:start, zone}, _from, state) do
    Logger.info("Starting zone #{zone.id}")
    World.Supervisor.start_child(zone)
    state = %{state | zones: [zone | state.zones]}
    {:reply, :ok, state}
  end

  def handle_call(:online_zones, _from, state) do
    {:reply, state.zones, state}
  end

  def handle_call({:stop_zones, zones}, _from, state) do
    stop_zones(zones)

    zone_ids = Enum.map(zones, &(&1.id))
    zones = Enum.reject(state.zones, fn (zone) ->
      zone.id in zone_ids
    end)

    state = %{state | zones: zones}

    {:reply, :ok, state}
  end

  def handle_info({:nodeup, _}, state), do: {:noreply, state}
  def handle_info({:nodedown, _}, state) do
    :erlang.send_after(500, self(), :maybe_shutdown)
    {:noreply, state}
  end

  def handle_info(:maybe_shutdown, state) do
    Logger.info("Looking for the master node to still be up")
    case :pg2.get_members(:zone_master) do
      [] ->
        Logger.info("Shutting down all zones")
        stop_zones(state.zones)
        state = %{state | zones: []}
        {:noreply, state}
      _ ->
        Logger.info("Master is up")
        {:noreply, state}
    end
  end

  defp stop_zones(zones) do
    Enum.each(zones, fn (zone) ->
      Zone.shutdown(zone.id)
      World.Supervisor.delete_child(zone.id)
    end)
  end
end
