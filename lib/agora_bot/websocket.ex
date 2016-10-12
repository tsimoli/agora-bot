defmodule AgoraBot.Websocket do
  @behaviour :websocket_client_handler
  import Logger

  def start_link(wss_url) do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
    client = :websocket_client
    put(%{:client => client})
    :crypto.start()
    :ssl.start()
    client.start_link(String.to_char_list(wss_url <> "/?v=5&encoding=json"), __MODULE__,[], [])
  end

  def init(state, socket) do
    Logger.info "Starting"
    put(%{:socket => socket, :status => :connecting})
    {:ok, state}
  end

  def websocket_info(:start, _connection, state) do
    {:ok, state}
  end

  def websocket_handle({:text, message}, _conn, state) do
    message = prepare_message message
    handle_message(message)
    {:ok, state}
  end

  def handle_message(message) do
    case Map.get(message, "op") do
      11 -> Logger.debug("PING")
      10 ->
        heartbeat_interval = Map.get(message, "d") |> Map.get("heartbeat_interval")
        AgoraBot.Heartbeater.start_heartbeat({:heartbeat, get(:socket), get(:client), heartbeat_interval})
        get(:client).send({:text, Poison.encode!(%AgoraBot.Identify{})}, get(:socket))
        put(%{:heartbeat_interval => heartbeat_interval, :status => :connected})
      _opcode -> type = Map.get(message, "t")
        case type do
          "READY" -> Logger.info "READY"
          "MESSAGE_CREATE" ->
            content = Map.get(message, "d") |> Map.get("content")
            if String.starts_with?(content, "!elo") do
              [prefix, player_to_find] = String.split(content, " ")
              paragon_url = "https://paragon.gg/players/" <> player_to_find
              paragon_response = Task.Supervisor.async(AgoraBot.TaskSupervisor, fn ->
                HTTPoison.get(paragon_url)
              end) |> Task.await()
              elo_and_league = parse_paragon_response(paragon_response)
              channel_id = Map.get(message, "d") |> Map.get("channel_id")
              discord_url = Application.get_env(:agora_bot, :endpoint) <> Application.get_env(:agora_bot, :channels) <> channel_id <> "/messages"
              HTTPoison.post(discord_url, Poison.encode!(%{content: "#{player_to_find} has #{elem(elo_and_league, 0)} elo rating in #{elem(elo_and_league, 1)} #{paragon_url}"}), %{"Authorization" => "Bot " <> Application.get_env(:agora_bot, :token), "Content-Type" => "application/json"})
            else
              Logger.info("Ignore")
            end
          _ -> Logger.info("Ignore")
        end
    end
  end

  def websocket_handle({:ping, data}, _conn, state) do
    {:reply, {:pong, data}, state}
  end

  defp parse_paragon_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    elo = Floki.find(body, ".elo") |> hd |> elem(2) |> hd
    league = Floki.find(body, ".rank") |> hd |> elem(2) |> hd
    {elo, league}
  end

  defp parse_paragon_response({:error, %HTTPoison.Response{status_code: code}}) do
    Logger.info("Failed to retrive elo information. Error code #{code}")
  end

  defp prepare_message(binstring) do
    binstring
    |> :binary.split(<<0>>)
    |> List.first
    |> Poison.Parser.parse!
  end

  def websocket_terminate(reason, conn, state) do
    Logger.info reason
  end

  def put(map) do
    Agent.update(__MODULE__, &Map.merge(&1, map))
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end
 end
