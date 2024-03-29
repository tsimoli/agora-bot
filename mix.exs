defmodule AgoraBot.Mixfile do
  use Mix.Project

  def project do
    [app: :agora_bot,
     version: "0.1.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {AgoraBot, []}, applications: [:logger, :httpoison, :poison, :websocket_client, :floki]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.9.0"},
     {:poison, "~> 2.0"},
     {:websocket_client, git: "https://github.com/jeremyong/websocket_client"},
     {:distillery, "~> 0.10"},
     {:floki, "~> 0.10.1"}]
  end
end
