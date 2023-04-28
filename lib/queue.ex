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
    {:ok, %{user_name: user_name}}
  end

  def get_name(user_name) do
    :"#{__MODULE__}#{String.capitalize(user_name)}"
  end
end
