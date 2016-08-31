defmodule AgoraBot.DiscordClient do
  use GenServer

  def start_link(_state) do
   GenServer.start_link(__MODULE__, Map.new, name: __MODULE__) 
  end

  def init(state) do
    HTTPoison.start
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- fetch_gateway(),
         {:ok, json_map} <- Poison.Parser.parse(body) do
         wss_url = Map.get(json_map, "url")
         AgoraBot.Websocket.start_link(wss_url)
         {:ok, state}
    else
         {:error, _reason} -> {:error, "Failed to initiate Discord client"}
    end
  end

  defp fetch_gateway() do
    HTTPoison.get(Application.get_env(:agora_bot, :endpoint) <> Application.get_env(:agora_bot, :gateway))
  end
 end
