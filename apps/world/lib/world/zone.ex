defmodule World.Zone do
  use GenServer
  require Logger

  def start_link(zone) do
    GenServer.start_link(__MODULE__, zone)
  end

  def init(zone) do
    Logger.info("Zone started #{zone.id}")
    #GenServer.cast(self(), :join)
    {:ok, zone}
  end

  def handle_cast(:join, state) do
    {:noreply, state}
  end
end
