defmodule ConsumerConnectionHandler do
  require Logger

  def serve(socket, state \\ %{current_user: nil}) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Consumer Data Received")
        state = handle_command(socket, data, state)
        serve(socket, state)

      {:error, :closed} ->
        Logger.info("Consumer Connection Closed")
    end
  end

  defp handle_command(socket, string, state) do
    string =
      string
      |> String.trim()
      |> String.downcase()
      |> String.split()

    case string do
      ["user", user_name] -> handle_user_command(socket, state, user_name)
      ["subscribe", topic] -> handle_subscribe_command(socket, state, topic)
      ["unsubscribe", topic] -> handle_unsubscribe_command(socket, state, topic)
      _ -> handle_unknown_command(socket, state)
    end
  end

  defp handle_user_command(socket, state, user_name) do
    case state.current_user do
      nil ->
        put_queue(user_name)
        :gen_tcp.send(socket, "\r\nUser was set to #{user_name}")
        state |> Map.put(:current_user, user_name)

      _ ->
        :gen_tcp.send(
          socket,
          "\r\nCannot change user, create new connection to act as a different user"
        )

        state
    end
  end

  defp put_queue(user_name) do
    case Supervisor.start_child(QueueSupervisor, Queue.child_spec(user_name)) do
      {:ok, _pid} ->
        Logger.info("Queue for user #{user_name} has been created")

      {:error, {:already_started, _pid}} ->
        Logger.info("Queue for user #{user_name} already exists, it is going to be reused")
    end
  end

  defp handle_subscribe_command(socket, state, topic) do
    :gen_tcp.send(socket, "\r\nSubscribed to topic #{topic}")
    state
  end

  defp handle_unsubscribe_command(socket, state, topic) do
    :gen_tcp.send(socket, "\r\nUnsubscribed from topic #{topic}")
    state
  end

  defp handle_unknown_command(socket, state) do
    :gen_tcp.send(socket, "\r\nCommand has the wrong format")
    state
  end
end
