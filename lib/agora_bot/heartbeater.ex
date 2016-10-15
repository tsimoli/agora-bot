defmodule AgoraBot.Heartbeater do
  use GenServer

  def start_link(_params) do
    GenServer.start_link(__MODULE__, %{:last_seq => Nil}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def start_heartbeat(args) do
    Process.send_after(__MODULE__, args, 500)
  end

  def save_last_seq(seq) do
    GenServer.cast(__MODULE__, {:set_last_seq, seq})
  end

  def handle_cast({:set_last_seq, last_seq}, state) do
    {:noreply, %{state | :last_seq => last_seq}}
  end

  def handle_info(args = {:heartbeat, socket, client, interval}, state = %{:last_seq => last_seq}) do
    beat_payload = %AgoraBot.Heartbeat{}
    client.send({:text, Poison.encode!(%{beat_payload | d: last_seq})}, socket)
    Process.send_after(__MODULE__, args, interval)
    {:noreply, state}
  end
end
