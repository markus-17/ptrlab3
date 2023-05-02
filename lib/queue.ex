defmodule Queue do
  use GenServer

  def start_link(user_name) do
    GenServer.start_link(__MODULE__, user_name, name: get_name(user_name))
  end

  def child_spec(user_name) do
    %{
      id: get_name(user_name),
      start: {Queue, :start_link, [user_name]}
    }
  end

  @impl true
  def init(user_name) do
    {:ok, %{user_name: user_name, topics: MapSet.new(), sockets: []}}
  end

  @impl true
  def handle_call({:subscribe, topic}, _from, state) do
    new_topics = state.topics |> MapSet.put(topic)
    {:reply, :ok, state |> Map.put(:topics, new_topics)}
  end

  @impl true
  def handle_call({:get_topics}, _from, state) do
    {:reply, state.topics |> Enum.to_list(), state}
  end

  @impl true
  def handle_call({:unsubscribe, topic}, _from, state) do
    new_topics = state.topics |> MapSet.delete(topic)
    {:reply, :ok, state |> Map.put(:topics, new_topics)}
  end

  @impl true
  def handle_call({:add_socket, socket}, _from, state) do
    sockets = state.sockets ++ [socket]
    {:reply, :ok, state |> Map.put(:sockets, sockets)}
  end

  @impl true
  def handle_cast({:message, {topic, message}}, state) do
    case state.topics |> Enum.member?(topic) do
      true ->
        sockets =
          state.sockets
          |> Enum.reduce([], fn socket, acc ->
            list =
              case :gen_tcp.send(socket, "\r\n#{message}") do
                :ok -> [socket]
                {:error, _} -> []
              end

            acc ++ list
          end)

        {:noreply, state |> Map.put(:sockets, sockets)}

      false ->
        {:noreply, state}
    end
  end

  def subscribe(server, topic) do
    :ok = GenServer.call(server, {:subscribe, topic})
  end

  def get_topics(server) do
    GenServer.call(server, {:get_topics})
  end

  def unsubscribe(server, topic) do
    :ok = GenServer.call(server, {:unsubscribe, topic})
  end

  def add_socket(server, socket) do
    :ok = GenServer.call(server, {:add_socket, socket})
  end

  def send_message(server, topic, message) do
    GenServer.cast(server, {:message, {topic, message}})
  end

  def get_name(user_name) do
    :"#{__MODULE__}#{String.capitalize(user_name)}"
  end
end
