defmodule Game.ZoneMaster do
  @moduledoc """
  The zone master will control where zones go on each node
  """

  use GenServer
  require Logger

  alias World.ZoneController

  @zones [%{id: 1}, %{id: 2}, %{id: 3}, %{id: 4}, %{id: 5}, %{id: 6}, %{id: 7}]

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def init(_) do
    :erlang.send_after(5000, self(), :start_zones)
    :ok = :net_kernel.monitor_nodes(true)
    {:ok, %{online: false}}
  end

  def handle_info(:start_zones, state) do
    Logger.info("Spinning up zones")
    :ok = :pg2.create(:zone_controllers)
    :erlang.send_after(500, self(), :rebalance)
    {:noreply, %{state | online: true}}
  end

  def handle_info({:nodeup, node_name}, state = %{online: true}) do
    Logger.info("Node is online #{inspect(node_name)}")
    :erlang.send_after(500, self(), :rebalance)
    {:noreply, state}
  end
  def handle_info({:nodeup, _node}, state), do: {:noreply, state}

  def handle_info({:nodedown, node_name}, state) do
    Logger.info("Node is down #{inspect(node_name)}")
    :erlang.send_after(500, self(), :rebalance)
    {:noreply, state}
  end

  def handle_info(:rebalance, state) do
    members = :pg2.get_members(:zone_controllers)

    members_with_zones = get_member_zones(members)

    zone_count = length(@zones)
    member_count = length(members)
    max_zones = round(Float.ceil(zone_count / member_count))

    Enum.each(members_with_zones, fn ({controller, zones}) ->
      zones = Enum.slice(zones, max_zones..-1)
      ZoneController.stop_zones(controller, zones)
    end)

    members_with_zones = get_member_zones(members)

    @zones
    |> Enum.reject(fn (zone) ->
      Enum.any?(members_with_zones, fn ({_, zones}) ->
        Enum.any?(zones, &(&1.id == zone.id))
      end)
    end)
    |> restart_zones(members_with_zones, max_zones)

    {:noreply, state}
  end

  defp get_member_zones(members) do
    Enum.map(members, fn (controller) ->
      {controller, ZoneController.online_zones(controller)}
    end)
  end

  defp restart_zones(zones, [], _max_zones) do
    raise "Something bad happened, ran out of nodes to place these zones #{inspect(zones)}"
  end
  defp restart_zones([], _controllers, _max_zones), do: :ok
  defp restart_zones([zone | zones], [{controller, controller_zones} | controllers_with_zones], max_zones) do
    case length(controller_zones) >= max_zones do
      true -> restart_zones([zone | zones], controllers_with_zones, max_zones)
      false ->
        Logger.info "Starting zone on #{inspect(controller)}"
        ZoneController.start_zone(controller, zone)
        restart_zones(zones, [{controller, controller_zones} | controllers_with_zones], max_zones)
    end
  end
end
