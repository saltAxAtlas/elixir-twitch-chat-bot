defmodule LoginHandler do
  use GenServer

  @moduledoc """
  Listens for login events and then joins the appropriate channels.
  """
  def start_link([client, channels]) do
    GenServer.start_link(__MODULE__, [client, channels])
  end

  def init([client, channels]) do
    ExIRC.Client.add_handler(client, self())
    {:ok, {client, channels}}
  end

  def handle_info(:logged_in, state = {client, channels}) do
    debug("Logged in to server")
    channels |> Enum.map(&ExIRC.Client.join(client, &1))
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp debug(msg) do
    IO.puts(IO.ANSI.yellow() <> msg <> IO.ANSI.reset())
  end
end
