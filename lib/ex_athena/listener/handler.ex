defmodule ExAthena.Listener.Handler do
  @moduledoc false

  require Logger

  alias ExAthena.Listener
  alias ExAthena.Listener.Supervisor

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @otp_app Keyword.fetch!(opts, :otp_app)

      use GenServer
      require Logger

      @impl true
      def init(socket) do
        :inet.setopts(socket, active: true)
        {:ok, socket}
      end

      def start_link(socket) when is_port(socket) do
        GenServer.start_link(__MODULE__, socket, name: {:global, socket})
      end

      @impl true
      def handle_info({:tcp, socket, data}, _state) do
        Logger.info("Received message: #{inspect(data)}")
        {:noreply, socket}
      end

      def handle_info({:tcp_closed, socket}, _state) do
        Logger.warn("Socket closed")
        {:noreply, socket}
      end

      def handle_info({:tcp_error, socket, reason}, _state) do
        Logger.error("Socket error: #{inspect(reason)}")
        {:noreply, socket}
      end
    end
  end

  @doc """
  Start the listening loop.
  """
  @spec start_listening(atom(), atom(), port()) :: no_return()
  def start_listening(otp_app, mod, listen_socket)
      when is_atom(otp_app) and is_atom(mod) and is_port(listen_socket) do
    handler = Listener.get_config(otp_app, mod, :handler)

    do_start_listening(listen_socket, handler)
  end

  defp do_start_listening(listen_socket, handler)
       when is_port(listen_socket) and is_atom(handler) do
    with {:ok, client_socket} <- :gen_tcp.accept(listen_socket) do
      start_handler(client_socket, handler)
    end

    do_start_listening(listen_socket, handler)
  end

  defp start_handler(client_socket, handler) when is_port(client_socket) and is_atom(handler) do
    with {:module, _} <- Code.ensure_compiled(handler),
         {:ok, pid} <- start_child(handler, client_socket) do
      :gen_tcp.controlling_process(client_socket, pid)
    end
  end

  defp start_child(handler, client_socket) do
    DynamicSupervisor.start_child(Supervisor, %{
      id: client_socket,
      start: {handler, :start_link, [client_socket]},
      type: :worker
    })
  end
end
