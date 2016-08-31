defmodule AgoraBot do
  use Application

  def start(_type, _args) do
    AgoraBot.Supervisor.start_link
  end
end
