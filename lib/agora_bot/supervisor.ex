defmodule AgoraBot.Supervisor do
  use Supervisor

  def start_link do
   Supervisor.start_link(__MODULE__, :ok, name: __MODULE__) 
  end

  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: AgoraBot.TaskSupervisor]]),
      worker(AgoraBot.DiscordClient, [[]]),
      worker(AgoraBot.Heartbeater, [[]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
