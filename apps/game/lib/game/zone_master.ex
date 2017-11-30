defmodule Game.ZoneMaster do
  @moduledoc """
  The zone master will control where zones go on each node
  """

  use GenServer
  require Logger

  alias World.ZoneController

  @ets_table :zone_locations
  @zones [%{id: 1}, %{id: 2}, %{id: 3}, %{id: 4}, %{id: 5}, %{id: 6}]

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def init(_) do
    :ets.new(@ets_table, [:bag, :protected, :named_table])
    :erlang.send_after(5000, self(), :start_zones)
    :ok = :net_kernel.monitor_nodes(true)

    {:ok, %{}}
  end

  def handle_info(:start_zones, state) do
    Logger.info("Spinning up zones")

    :ok = :pg2.create(:zone_controllers)

    members = :pg2.get_members(:zone_controllers)

    @zones
    |> start_zones(members)

    {:noreply, state}
  end

  def handle_info({:nodeup, _node}, state), do: {:noreply, state}
  def handle_info({:nodedown, node_name}, state) do
    zones =
      @ets_table
      |> :ets.lookup(node_name)
      |> Enum.map(&(elem(&1, 1)))
      |> zones()

    :ets.delete(@ets_table, node_name)

    :erlang.send_after(500, self(), {:restart_zones, zones})

    {:noreply, state}
  end
  def handle_info({:restart_zones, zones}, state) do
    members = :pg2.get_members(:zone_controllers)
    start_zones(zones, members)
    {:noreply, state}
  end

  defp zones(zone_ids) do
    @zones
    |> Enum.filter(fn (zone) ->
      zone.id in zone_ids
    end)
  end

  defp start_zones(zones, members) do
    member_count = length(members)

    zones
    |> Enum.with_index()
    |> Enum.each(fn ({zone, index}) ->
      controller = Enum.at(members, rem(index, member_count))
      node_name = ZoneController.start_zone(controller, zone)
      :ets.insert(@ets_table, {node_name, zone.id})
    end)
  end
end
