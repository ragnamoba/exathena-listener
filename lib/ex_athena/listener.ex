defmodule ExAthena.Listener do
  @moduledoc false

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @otp_app Keyword.fetch!(opts, :otp_app)

      use GenServer
      require Logger

      @default_socket_options [:binary, active: false, reuseaddr: true]
      @defaul_opts [handler: nil, socket_options: @default_socket_options, port: 6900]

      defp __config__,
        do: Application.get_env(@otp_app, __MODULE__, @defaul_opts)

      defp config(key, default \\ nil) when is_atom(key),
        do: Keyword.get(__config__(), key, default)

      @impl true
      def init(_args) do
        port = config(:port, 6900)
        options = config(:socket_options, @default_socket_options)

        :gen_tcp.listen(port, options)
      end

      def child_spec(listen_socket) do
        default = %{
          id: __MODULE__,
          name: __MODULE__,
          start: {__MODULE__, :start_link, [listen_socket]},
          type: :supervisor
        }

        Supervisor.child_spec(default, [])
      end

      def start_link(state \\ nil) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      def socket, do: GenServer.call(__MODULE__, :socket)

      # Callbacks

      @impl true
      def handle_info({:tcp, socket, packet}, state) do
        Logger.info("Received packet: #{inspect(packet)} and send response")
        :gen_tcp.send(socket, "Hi from tcp server \n")
        {:noreply, state}
      end

      @impl true
      def handle_info({:tcp_closed, _socket}, state) do
        Logger.info("Socket is closed")
        {:stop, {:shutdown, "Socket is closed"}, state}
      end

      @impl true
      def handle_info({:tcp_error, _socket, reason}, state) do
        Logger.error("Tcp error: #{inspect(reason)}")
        {:stop, {:shutdown, "Tcp error: #{inspect(reason)}"}, state}
      end

      @impl true
      def handle_call(:socket, _from, state) do
        {:reply, state, state}
      end

      @impl true
      def format_status(_reason, _state) do
        :ok
      end

      @impl true
      def terminate(_reason, _state) do
        :ok
      end

      @impl true
      def code_change(_old_version, state, _extra) do
        {:ok, state}
      end
    end
  end
end
