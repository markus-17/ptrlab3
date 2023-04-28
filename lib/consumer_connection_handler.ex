defmodule ConsumerConnectionHandler do
  require Logger

  def serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Consumer Data Received")
        handle_command(socket, data)
        serve(socket)

      {:error, :closed} ->
        Logger.info("Consumer Connection Closed")
    end
  end

  defp handle_command(socket, string) do
    string =
      string
      |> String.trim()
      |> String.downcase()
      |> String.split()

    case string do
      ["user", user_name] ->
        :gen_tcp.send(socket, "\r\nUser was set to #{user_name}")

      ["subscribe", topic] ->
        :gen_tcp.send(socket, "\r\nSubscribed to topic #{topic}")

      ["unsubscribe", topic] ->
        :gen_tcp.send(socket, "\r\nUnsubscribed from topic #{topic}")

      _ ->
        :gen_tcp.send(socket, "\r\nCommand has the wrong format")
    end
  end
end
