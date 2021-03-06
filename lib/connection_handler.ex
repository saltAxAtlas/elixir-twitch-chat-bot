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
              prefix: "%",
              dictionary: nil,
              # Implement functionality for counters
              counter_table: nil,
              gif_api_key: Application.get_env(:twitch_chat_bot, :giphy_api_key),
              # requires api_key & q (set limit to 50)
              gif_search_endpoint: "api.giphy.com/v1/gifs/search",
              gif_trending_endpoint: "api.giphy.com/v1/gifs/trending"
  end

  def start_link(client, state \\ %State{}) do
    GenServer.start_link(__MODULE__, [%{state | client: client}])
  end

  def init([state]) do
    ExIRC.Client.add_handler(state.client, self())
    ExIRC.Client.connect!(state.client, state.host, state.port)
    {:ok, state, {:continue, :get_dictionary}}
  end

  def handle_continue(:get_dictionary, state) do
    dictionary =
      File.read("long_dict.txt")
      |> elem(1)
      |> String.split("\n", trim: true)
      |> Enum.map(fn x -> String.downcase(x) end)

    state = Map.put(state, :dictionary, dictionary)

    # state = Map.put(state, :counter_table, :dets.open_file(:disk_storage, [type: :set])) # Needs testing
    {:noreply, state}
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
    if String.first(message) == state.prefix && sender.nick != state.nick do
      handle_command(message, channel, state)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:mentioned, message, sender, channel}, state) do
    debug("#{sender.nick} mentioned us in #{channel}: #{message}")

    ExIRC.Client.msg(
      state.client,
      :privmsg,
      channel,
      Enum.random(["Hello?", "What do you want?", "Please don't talk to me...", "No."])
    )

    {:noreply, state}
  end

  def handle_info({:names_list, _channel, _names}, state) do
    # debug("Name list for channel #{channel}: #{names}")
    {:noreply, state}
  end

  def handle_info({:unrecognized, _value, _ircmsg}, state) do
    # debug("Unrecognized message: #{ircmsg.cmd}")
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
      "help" ->
        help_command(msg_list, channel, state)

      "commands" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "help, commands, say, tgif, gif, wos, color, flip, roll")

      "say" ->
        ExIRC.Client.msg(
          state.client,
          :privmsg,
          channel,
          msg_list |> Enum.drop(1) |> Enum.join(" ") |> String.replace(~r/[\/.]/, "")
        )

      "tgif" ->
        gif_trending_command(channel, state)

      "gif" ->
        gif_search_command(msg_list, channel, state)

      "wos" ->
        wos_command(msg_list, channel, state)

      "color" ->
        color_command(msg_list, channel, state)

      "flip" ->
        coin_flip_command(channel, state)

      "roll" ->
        dice_roll_command(msg_list, channel, state)

      _ ->
        {:noreply, state}
    end
  end

  defp find_words(dictionary, chars, len) do
    search_letters = String.downcase(chars)

    dictionary
    |> Enum.filter(fn x ->
      String.length(x) == len &&
        Multiset.subset?(
          x
          |> String.graphemes()
          |> Multiset.new(),
          search_letters
          |> String.graphemes()
          |> Multiset.new()
        )
    end)
    |> Enum.join(", ")
  end

  defp wos_command([_cmd, chars, len], channel, state) do
    output =
      case Integer.parse(len) do
        {len, _} -> find_words(state.dictionary, chars, len)
        _ -> "Expected Input: %wos chars length"
      end

    ExIRC.Client.msg(state.client, :privmsg, channel, output)
    {:noreply, state}
  end

  defp wos_command(_msg_list, _channel, state) do
    {:noreply, state}
  end

  defp color_command(msg_list, channel, state) do
    ExIRC.Client.msg(state.client, :privmsg, channel, "/color #{msg_list |> List.last()}")
    ExIRC.Client.msg(state.client, :privmsg, channel, "color updated to: #{msg_list |> List.last()}")
    {:noreply, state}
  end

  defp gif_trending_command(channel, state) do
    {:ok, response} =
      HTTPoison.get(state.gif_trending_endpoint, [],
        params: [api_key: state.gif_api_key, limit: 50]
      )

    output =
      response.body
      |> Poison.decode!()
      |> Map.fetch("data")
      |> elem(1)
      |> Enum.map(fn x -> Map.fetch(x, "embed_url") |> elem(1) end)
      |> Enum.shuffle()
      |> List.first()

    ExIRC.Client.msg(state.client, :privmsg, channel, "#{output}")
    {:noreply, state}
  end

  defp gif_search_command(msg_list, channel, state) do
    {:ok, response} =
      HTTPoison.get(state.gif_search_endpoint, [],
        params: [api_key: state.gif_api_key, q: "#{msg_list |> Enum.drop(1) |> Enum.join(" ")}", limit: 50]
      )

    output =
      response.body
      |> Poison.decode!()
      |> Map.fetch("data")
      |> elem(1)
      |> Enum.map(fn x -> Map.fetch(x, "embed_url") |> elem(1) end)
      |> Enum.shuffle()
      |> List.first()

    ExIRC.Client.msg(state.client, :privmsg, channel, "#{output}")
    {:noreply, state}
  end

  defp coin_flip_command(channel, state) do
    ExIRC.Client.msg(
      state.client,
      :privmsg,
      channel,
      Enum.random(["Heads!", "Tails!"])
    )
    {:noreply, state}
  end

  defp dice_roll_command(msg_list, channel, state) do
    n = msg_list |> Enum.drop(1) |> List.first()
    if n == nil do
      ExIRC.Client.msg(state.client, :privmsg, channel, :rand.uniform(6) |> Integer.to_string())
    else
      case Integer.parse(n) do
        {n, _} -> ExIRC.Client.msg(state.client, :privmsg, channel, :rand.uniform(n) |> Integer.to_string())
        _ -> ExIRC.Client.msg(state.client, :privmsg, channel, :rand.uniform(6) |> Integer.to_string())
      end
    end
    {:noreply, state}
  end

  defp help_command(msg_list, channel, state) do
    case Enum.at(msg_list, 1) do
      "help" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%help {command name}")

      "commands" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%commands -> sends the command list")

      "say" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%say {input} -> repeats `input`")

      "tgif" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%tgif -> sends link to a trending gif")

      "gif" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%gif {input} -> sends link to a gif relating to `input`")

      "wos" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%wos {characters} {length} -> sends a list of words of {length} matching the {characters}")

      "color" ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "%color {Blue, Coral, DodgerBlue, SpringGreen, YellowGreen, Green, OrangeRed, Red, GoldenRod, HotPink, CadetBlue, SeaGreen, Chocolate, BlueViolet, Firebrick}")

      nil ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "Type `%help {command name}` to see how to use a specific command")

      _ ->
        ExIRC.Client.msg(state.client, :privmsg, channel, "Not a valid command")
    end
  end
end
