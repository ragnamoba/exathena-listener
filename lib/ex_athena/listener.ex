defmodule ExAthena.Listener do
  @moduledoc false
  use Application

  @doc false
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: ExAthena.Listener.Supervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @otp_app Keyword.fetch!(opts, :otp_app)

      use GenServer
      require Logger

      alias ExAthena.Listener.Handler

      @default_socket_options [:binary, active: false, reuseaddr: true]
      @defaul_opts [handler: nil, socket_options: @default_socket_options, port: 6900]

      defp __config__ do
        config = Application.get_env(@otp_app, __MODULE__, [])

        Keyword.merge(@defaul_opts, config)
      end

      defp config(key, default \\ nil) when is_atom(key),
        do: Keyword.get(__config__(), key, default)

      @impl true
      def init(_args) do
        Application.put_env(@otp_app, __MODULE__, __config__())

        port = config(:port, 6900)
        options = config(:socket_options, @default_socket_options)

        with {:ok, listen_socket} <- :gen_tcp.listen(port, options) do
          {:ok, listen_socket, {:continue, :loop_acceptor}}
        end
      end

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      # Callbacks

      @impl true
      def handle_continue(:loop_acceptor, listen_socket) do
        send(self(), :accept)
        {:noreply, listen_socket}
      end

      @impl true
      def handle_info(:accept, listen_socket) do
        Handler.start_listening(@otp_app, __MODULE__, listen_socket)
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
  @spec get_config(atom(), atom(), atom()) :: any()
  def get_config(otp_app, mod, key) do
    otp_app
    |> Application.get_env(mod, [])
    |> Keyword.get(key)
  end
end
