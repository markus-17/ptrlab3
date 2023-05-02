defmodule ProducerConnectionHandler do
  require Logger

  def serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Producer Data Received")
        handle_message(data)
        serve(socket)

      {:error, :closed} ->
        Logger.info("Producer Connection Closed")
    end
  end

  defp handle_message(data) do
    [topic, message] =
      data
      |> String.trim()
      |> String.split("@")

    topic =
      topic
      |> String.trim()
      |> String.downcase()

    message =
      message
      |> String.trim()

    Supervisor.which_children(QueueSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      Queue.send_message(pid, topic, message)
    end)
  end
end
