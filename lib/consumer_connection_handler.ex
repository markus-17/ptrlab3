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
      ["get-topics"] -> handle_get_topics_command(socket, state)
      ["unsubscribe", topic] -> handle_unsubscribe_command(socket, state, topic)
      _ -> handle_unknown_command(socket, state)
    end
  end

  defp handle_user_command(socket, state, user_name) do
    case state.current_user do
      nil ->
        put_queue(user_name, socket)
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

  defp put_queue(user_name, socket) do
    case Supervisor.start_child(QueueSupervisor, Queue.child_spec(user_name)) do
      {:ok, _pid} ->
        Logger.info("Queue for user #{user_name} has been created")

      {:error, {:already_started, _pid}} ->
        Logger.info("Queue for user #{user_name} already exists, it is going to be reused")
    end
    Queue.get_name(user_name) |> Queue.add_socket(socket)
  end

  defp handle_subscribe_command(socket, state, topic) do
    case state.current_user do
      nil ->
        :gen_tcp.send(socket, "\r\nYou have to act as a user before subscribing to topics")

      user_name ->
        Queue.get_name(user_name) |> Queue.subscribe(topic)
        :gen_tcp.send(socket, "\r\nSubscribed to topic #{topic}")
    end

    state
  end

  defp handle_get_topics_command(socket, state) do
    case state.current_user do
      nil ->
        :gen_tcp.send(socket, "\r\nYou have to act as a user before viewing subscribed topics")

      user_name ->
        topics =
          Queue.get_name(user_name)
          |> Queue.get_topics()

        :gen_tcp.send(socket, "\r\n#{inspect(topics)}")
    end

    state
  end

  defp handle_unsubscribe_command(socket, state, topic) do
    case state.current_user do
      nil ->
        :gen_tcp.send(socket, "\r\nYou have to act as a user before unsubscribing from topics")

      user_name ->
        Queue.get_name(user_name) |> Queue.unsubscribe(topic)
        :gen_tcp.send(socket, "\r\nUnsubscribed from topic #{topic}")
    end

    state
  end

  defp handle_unknown_command(socket, state) do
    :gen_tcp.send(socket, "\r\nCommand has the wrong format")
    state
  end
end
