defmodule Game.ZoneMaster do
  @moduledoc """
  The zone master will control where zones go on each node
  """

  use GenServer

  alias World.ZoneController

  @zones [%{id: 1}, %{id: 3}]

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def init(_) do
    :erlang.send_after(5000, self(), :start_zones)
    {:ok, %{}}
  end

  def handle_info(:start_zones, state) do
    :ok = :pg2.create(:zone_controllers)

    members = :pg2.get_members(:zone_controllers)
    member_count = length(members)

    @zones
    |> Enum.with_index()
    |> Enum.each(fn ({zone, index}) ->
      controller = Enum.at(members, rem(index, member_count))
      ZoneController.start_zone(controller, zone)
    end)

    {:noreply, state}
  end
end
