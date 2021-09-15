defmodule TwitchChatBot do
    use Application
    @moduledoc """
    Documentation for `TwitchChatBot`.
    """

    @impl true
    def start(_type, _args) do
        {:ok, client} = ExIRC.start_link!

        children = [
            {ConnectionHandler, client},
            {LoginHandler, [client, [Application.get_env(:twitch_chat_bot, :channel_name)]]}
        ]

        opts = [strategy: :one_for_one, name: TwitchChatBot.Supervisor]
        Supervisor.start_link(children, opts)
    end
end
