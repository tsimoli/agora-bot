defmodule AgoraBot.Websocket do
  @behaviour :websocket_client_handler
  import Logger

  def start_link(wss_url) do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
    client = :websocket_client
    save_to_agent(%{:client => client})
    :crypto.start()
    :ssl.start()
    client.start_link(String.to_char_list(wss_url <> "/?v=5&encoding=json"), __MODULE__,[], [])
  end

  def init(state, socket) do
    Logger.info "Starting"
    save_to_agent(%{:socket => socket, :status => :connecting})
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
        connection_established(message)
      _opcode -> 
        handle_channel_messages(message)
    end
  end

  defp connection_established(message) do
    heartbeat_interval = Map.get(message, "d") |> Map.get("heartbeat_interval")
    AgoraBot.Heartbeater.start_heartbeat({:heartbeat, fetch_from_agent(:socket), fetch_from_agent(:client), heartbeat_interval})
    fetch_from_agent(:client).send({:text, Poison.encode!(%AgoraBot.Identify{})}, fetch_from_agent(:socket))
    save_to_agent(%{:heartbeat_interval => heartbeat_interval, :status => :connected})
  end

  defp handle_channel_messages(message) do
    type = Map.get(message, "t")
        AgoraBot.Heartbeater.save_last_seq(Map.get(message, "s"))
        case type do
          "READY" -> Logger.info "READY"
          "MESSAGE_CREATE" ->
            content = Map.get(message, "d") |> Map.get("content")
            if String.starts_with?(content, "!elo") do
              Logger.info "Fetching elo"
              player_to_find = case String.split(content, " ") do
                [prefix, player_to_find] -> player_to_find
                _ -> ""
              end
              paragon_url = "https://paragon.gg/players/" <> player_to_find
              paragon_response = Task.Supervisor.async(AgoraBot.TaskSupervisor, fn ->
                HTTPoison.get(paragon_url)
              end) |> Task.await()
              channel_id = Map.get(message, "d") |> Map.get("channel_id")
              discord_url = Application.get_env(:agora_bot, :endpoint) <> Application.get_env(:agora_bot, :channels) <> channel_id <> "/messages"
              case parse_paragon_response(paragon_response) do
                {:ok, {elo, league}} ->
                  HTTPoison.post(discord_url, Poison.encode!(%{content: "#{player_to_find} has #{elo} elo rating in #{league} #{paragon_url}"}), %{"Authorization" => "Bot " <> Application.get_env(:agora_bot, :token), "Content-Type" => "application/json"})
                {:error, reason} ->
                  HTTPoison.post(discord_url, Poison.encode!(%{content: reason}), %{"Authorization" => "Bot " <> Application.get_env(:agora_bot, :token), "Content-Type" => "application/json"})
              end
            else
              Logger.info("Ignore")
            end
          _ -> 
            Logger.info("Ignore")
        end
  end

  def websocket_handle({:ping, data}, _conn, state) do
    {:reply, {:pong, data}, state}
  end

  defp parse_paragon_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    elo = Floki.find(body, ".elo") |> hd |> elem(2) |> hd
    league = Floki.find(body, ".rank") |> hd |> elem(2) |> hd
    {:ok, {elo, league}}
  end

  defp parse_paragon_response({_, %HTTPoison.Response{status_code: code}}) do
    Logger.error "Search failer with code: #{code}"
    reason = case code do
      302 -> "player not found"
      500 -> "could not connect to server"
      _ -> "search failed for unknown reason"
    end
    {:error, reason}
  end

  defp prepare_message(binstring) do
    binstring
    |> :binary.split(<<0>>)
    |> List.first
    |> Poison.Parser.parse!
  end

  def websocket_terminate(reason, conn, state) do
    Logger.error "Websocket failed with reason: " <>reason
  end

  defp save_to_agent(map) do
    Agent.update(__MODULE__, &Map.merge(&1, map))
  end

  defp fetch_from_agent(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end
 end
