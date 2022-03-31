defmodule ExAthena.Listener do
  @moduledoc false

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @otp_app Keyword.fetch!(opts, :otp_app)

      use GenServer
      require Logger

      @default_socket_options [
        :binary,
        packet: 0,
        active: false,
        reuseaddr: true
      ]

      @defaul_opts [handler: nil, socket_options: @default_socket_options, port: 6900]

      defp __config__,
        do: Application.get_env(@otp_app, __MODULE__, @defaul_opts)

      defp config(key, default \\ nil) when is_atom(key),
        do: Keyword.get(__config__(), key, default)

      @impl true
      def init(_args) do
        pid = self()
        port = config(:port, 6900)
        options = config(:socket_options, @default_socket_options)
        handler = config(:handler, :noop)

        with {:ok, listen_socket} <- :gen_tcp.listen(port, options) do
          send(pid, :accept)
          {:ok, %{port: port, socket: listen_socket, handler: handler}}
        end
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

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      # Callbacks

      @impl true
      def handle_info(:accept, state = %{socket: listen_socket, handler: handler}) do
        ExAthena.Listener.__listening__(listen_socket, handler)
        {:noreply, state}
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

  @doc false
  def __listening__(listen_socket, handler) when is_port(listen_socket) and is_atom(handler) do
    with {:ok, client_socket} <- :gen_tcp.accept(listen_socket) do
      IO.puts("Received connection: " <> inspect(client_socket))

      __route_socket__(client_socket)
    end

    __listening__(listen_socket, handler)
  end

  defp __route_socket__(client_socket) when is_port(client_socket) do
    client_socket
    |> :gen_tcp.recv(0)
    |> IO.inspect(label: inspect(client_socket))
  end
end

defmodule Alo do
  use ExAthena.Listener, otp_app: :exathena_listener
end
