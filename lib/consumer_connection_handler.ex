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
        put_queue(user_name, socket)
        :gen_tcp.send(socket, "\r\nUser was set to #{user_name}")

      ["subscribe", topic] ->
        :gen_tcp.send(socket, "\r\nSubscribed to topic #{topic}")

      ["unsubscribe", topic] ->
        :gen_tcp.send(socket, "\r\nUnsubscribed from topic #{topic}")

      _ ->
        :gen_tcp.send(socket, "\r\nCommand has the wrong format")
    end
  end

  defp put_queue(user_name, _socket) do
    case Supervisor.start_child(QueueSupervisor, Queue.child_spec(user_name)) do
      {:ok, _pid} ->
        Logger.info("Queue for user #{user_name} has been created")

      {:error, {:already_started, _pid}} ->
        Logger.info("Queue for user #{user_name} already exists, it is going to be reused")
    end
  end
end
