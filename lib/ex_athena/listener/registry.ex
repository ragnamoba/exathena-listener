defmodule ExAthena.Listener.Registry do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def associate(pid, name, value) when is_pid(pid) do
    GenServer.call(__MODULE__, {:associate, pid, name, value})
  end

  def all_running() do
    for [pid, name] <- :ets.match(__MODULE__, {:"$1", :_, :"$2"}) do
      name || pid
    end
  end

  def lookup(listener) when is_atom(listener) do
    listener
    |> GenServer.whereis()
    |> Kernel.||(
      raise "could not lookup ExAthena Listener #{inspect(listener)} because it was not started or it does not exist"
    )
    |> lookup()
  end

  def lookup(pid) when is_pid(pid) do
    :ets.lookup_element(__MODULE__, pid, 4)
  end

  ## Callbacks

  @impl true
  def init(:ok) do
    table = :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    {:ok, table}
  end

  @impl true
  def handle_call({:associate, pid, name, _value}, _from, table) do
    ref = Process.monitor(pid)
    true = :ets.insert(table, {pid, ref, name})
    {:reply, :ok, table}
  end

  @impl true
  def handle_info({:DOWN, ref, _type, pid, _reason}, table) do
    [{^pid, ^ref, _meta}] = :ets.lookup(table, pid)
    :ets.delete(table, pid)
    {:noreply, table}
  end
end
