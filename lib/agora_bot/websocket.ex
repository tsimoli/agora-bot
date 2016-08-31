defmodule AgoraBot.Websocket do
  @behaviour :websocket_client_handler
  import Logger

  def start_link(wss_url) do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
    client = :websocket_client
    put(%{:client => client})
    :crypto.start()
    :ssl.start()
    client.start_link("wss://gateway.discord.gg/?v=5&encoding=json", __MODULE__,[], [])
  end

  def init(state, socket) do
    IO.puts "Starting"
    IO.inspect socket
    put(%{:socket => socket, :status => :connecting})
    {:ok, state}
  end

  def websocket_info(:start, _connection, state) do
    {:ok, state}
  end

  def websocket_handle({:text, message}, _conn, state) do
    message = prepare_message message
    IO.inspect message
    handle_message(message, get(:status))
    {:ok, state}
  end

  def handle_message(message, :connecting) do
    case Map.get(message, "op") do
      11 -> IO.puts "PING"
      10 ->
        heartbeat_interval = Map.get(message, "d") |> Map.get("heartbeat_interval")
        AgoraBot.Heartbeater.start_heartbeat({:heartbeat, get(:socket), get(:client), heartbeat_interval})
        get(:client).send({:text, Poison.encode!(%AgoraBot.Identify{})}, get(:socket))
        put(%{:heartbeat_interval => heartbeat_interval, :status => :connected})
    end
  end

  def websocket_handle({:ping, data}, _conn, state) do
    {:reply, {:pong, data}, state}
  end

  def handle_message(message, :connected) do
    case Map.get(message, "op") do
      11 -> IO.puts "PING"
      _ -> type = Map.get(message, "t")
      Logger.info type
      case type do
        "READY" -> IO.puts "READY"
        "MESSAGE_CREATE" ->
          if Map.get(message, "d") |> Map.get("content") == "!elo" do
            channel_id = Map.get(message, "d") |> Map.get("channel_id")
            IO.puts channel_id
            url = Application.get_env(:agora_bot, :endpoint) <> Application.get_env(:agora_bot, :channels) <> channel_id <> "/messages"
            IO.puts url
            response = HTTPoison.post(url, Poison.encode!(%{content: "TODO: parsing"}),%{"Authorization" => Application.get_env(:agora_bot, :token), "Content-Type" => "application/json"})
            IO.inspect response
          else
            IO.puts "Do nothing"
          end
        _ -> IO.inspect type
      end
      IO.puts "LOOPED"
    end
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
