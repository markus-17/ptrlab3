defmodule ConsumerConnectionHandler do
  require Logger

  def serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Consumer Data Received")
        :gen_tcp.send(socket, "#{data |> String.trim}___")
        serve(socket)

      {:error, :closed} ->
        Logger.info("Consumer Connection Closed")
    end
  end
end
