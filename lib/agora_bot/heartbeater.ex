defmodule AgoraBot.Heartbeater do
  use GenServer

  def start_link(_params) do
    GenServer.start_link(__MODULE__, [], name: Heartbeater)
  end

  def init(state) do
    {:ok, state}
  end

  def start_heartbeat(args) do
    Process.send_after(Heartbeater, args, 500)
  end

  def handle_info(args = {:heartbeat, socket, client, interval}, state) do
    client.send({:text, Poison.encode!(%AgoraBot.Heartbeat{})}, socket)
    Process.send_after(Heartbeater, args, interval)
    {:noreply, state}
  end
end
