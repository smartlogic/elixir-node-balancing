defmodule World.Zone do
  @moduledoc """
  A simple GenServer to spin up and down
  """

  use GenServer
  require Logger

  def start_link(zone) do
    GenServer.start_link(__MODULE__, zone, name: pid(zone.id))
  end

  defp pid(id), do: {:via, Registry, {World.ZoneRegistry, id}}

  def shutdown(id) when is_integer(id) do
    GenServer.call(pid(id), :shutdown)
  end

  def init(zone) do
    Logger.info("Zone started #{zone.id}")
    {:ok, zone}
  end

  def handle_call(:shutdown, _from, state) do
    Logger.info("Stopping zone #{state.id}")
    {:stop, :normal, :ok, state}
  end
end
