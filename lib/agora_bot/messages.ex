defmodule AgoraBot.Identify do
  defstruct op: 2, d: %{token: Application.get_env(:agora_bot, :token), properties: %{"$os" => "linux", "$browser" => "discord.js", "$device" => "discord.js", "$referrer" => "", "$referring_domain" => ""}, compress: false, large_threshold: 250}
end

defmodule AgoraBot.Heartbeat do
  defstruct op: 1, d: :os.system_time(:milli_seconds)
end

defmodule AgoraBot.Hello do
  defstruct heartbeat_interval: Nil, _trace: Nil
end
