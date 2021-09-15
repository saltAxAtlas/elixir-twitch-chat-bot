defmodule ConnectionHandler do
    use GenServer

    defmodule State do
        defstruct host: "irc.chat.twitch.tv",
                port: 6667,
                pass: Application.get_env(:twitch_chat_bot, :bot_pass),
                nick: Application.get_env(:twitch_chat_bot, :bot_name),
                user: "",
                name: "",
                client: nil,
                prefix: "%"
    end

    def start_link(client, state \\ %State{}) do
        GenServer.start_link(__MODULE__, [%{state | client: client}])
    end

    def init([state]) do
        ExIRC.Client.add_handler(state.client, self())
        ExIRC.Client.connect!(state.client, state.host, state.port)
        {:ok, state}
    end

    def handle_info({:connected, server, port}, state) do
        debug("Connected to #{server}:#{port}")
        ExIRC.Client.logon(state.client, state.pass, state.nick, state.user, state.name)
        {:noreply, state}
    end

    def handle_info(:logged_in, state) do
        {:noreply, state}
    end

    def handle_info({:login_failed, :nick_in_use}, state) do
        debug("Login failed -> nickname in use")
        {:noreply, state}
    end

    def handle_info(:disconnected, state) do
        debug("Disconnected from server :(")
        {:noreply, state}
    end

    def handle_info({:joined, channel}, state) do
        debug("Joined #{channel}")
        {:noreply, state}
    end

    def handle_info({:joined, channel, user}, state) do
        debug("#{user} joined #{channel}")
        {:noreply, state}
    end

    def handle_info({:parted, channel}, state) do
        debug("We left #{channel} -> that shouldn't have happened :(")
        {:noreply, state}
    end

    def handle_info({:parted, channel, sender}, state) do
        nick = sender.nick
        debug("#{nick} left #{channel} -> rip :(")
        {:noreply, state}
    end

    def handle_info({:kicked, sender, channel}, state) do
        debug("We were kicked from #{channel} by #{sender.nick}")
        {:noreply, state}
    end

    def handle_info({:kicked, nick, sender, channel}, state) do
        debug("#{nick} was kicked from #{channel} by #{sender.nick}")
        {:noreply, state}
    end

    def handle_info({:received, message, sender, channel}, state) do
        # debug("#{sender.nick} sent a message to #{channel}: #{message}")
        if String.first(message) == state.prefix && sender.nick != state.nick do
            handle_command(message, channel, state)
            {:noreply, state}
        else
            {:noreply, state}
        end
    end

    def handle_info({:mentioned, message, sender, channel}, state) do
        debug("#{sender.nick} mentioned us in #{channel}: #{message}")
        ExIRC.Client.msg(state.client, :privmsg, channel, Enum.random(["Hello?", "What do you want?", "Please don't talk to me...", "No."]))
        {:noreply, state}
    end

    def handle_info({:names_list, channel, names}, state) do
        debug("Name list for channel #{channel}: #{names}")
        {:noreply, state}
    end

    def handle_info({:unrecognized, _value, ircmsg}, state) do
        debug("Unrecognized message: #{ircmsg.cmd}")
        # IO.inspect(ircmsg)
        {:noreply, state}
    end

    # Catch-all for messages you don't care about
    def handle_info(msg, state) do
        debug("Received unknown messsage:")
        IO.inspect(msg)
        {:noreply, state}
    end

    defp debug(msg) do
        IO.puts(IO.ANSI.yellow() <> msg <> IO.ANSI.reset())
    end

    defp handle_command(msg, channel, state) do
        msg_list = msg |> String.split()
        case msg_list |> List.first(nil) |> String.slice(1..-1) do
            "say" -> ExIRC.Client.msg(state.client, :privmsg, channel, msg_list |> Enum.drop(1) |> Enum.join(" "))
            _ -> {:noreply, state}
        end
    end
end
