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
    {:ok, %{user_name: user_name, topics: MapSet.new()}}
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

  def subscribe(server, topic) do
    :ok = GenServer.call(server, {:subscribe, topic})
  end

  def get_topics(server) do
    GenServer.call(server, {:get_topics})
  end

  def get_name(user_name) do
    :"#{__MODULE__}#{String.capitalize(user_name)}"
  end
end
