defmodule World.ZoneController do
  @moduledoc """
  GenServer that connects with other zone controllers to spawn zones
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_zone(pid, zone) do
    GenServer.call(pid, {:start, zone})
  end

  def init(_) do
    :ok = :pg2.create(:zone_controllers)
    :ok = :pg2.join(:zone_controllers, self())
    {:ok, %{zones: []}}
  end

  def handle_call({:start, zone}, _from, state) do
    state = %{state | zones: [zone | state.zones]}
    IO.inspect state
    {:reply, :ok, state}
  end
end
