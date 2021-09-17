defmodule TwitchChatBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :twitch_chat_bot,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TwitchChatBot, []},
      applications: [:exirc],
      extra_applications: [:logger, :multiset]
    ]
  end

  defp deps do
    [
      {:exirc, "~> 2.0.0"},
      {:multiset, "~> 0.0.4"}
    ]
  end
end
