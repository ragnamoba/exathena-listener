defmodule ExAthena.Listener.Handler do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote do
      use GenServer

      @impl true
      def init(_args) do
      end

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end
    end
  end

  @doc """
  Start the listening loop.
  """
  @spec start_listening(port(), atom()) :: no_return()
  def start_listening(listen_socket, handler) when is_port(listen_socket) and is_atom(handler) do
    with {:ok, client_socket} <- :gen_tcp.accept(listen_socket) do
      start_handler(client_socket, handler)
    end

    start_listening(listen_socket, handler)
  end

  defp start_handler(client_socket, handler) when is_port(client_socket) and is_atom(handler) do
    with {:ok, data} <- :gen_tcp.recv(client_socket, 0) do
      IO.inspect(client_socket, label: :socket)
      IO.inspect(data, label: :data)
    end

    start_handler(client_socket, handler)
  end
end
