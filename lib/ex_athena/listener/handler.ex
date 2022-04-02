defmodule ExAthena.Listener.Handler do
  @moduledoc false

  require Logger

  alias ExAthena.Listener
  alias ExAthena.Listener.{Router, Supervisor}

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @otp_app Keyword.fetch!(opts, :otp_app)

      use GenServer
      require Logger

      alias ExAthena.Listener.{Handler, Parser, Router}

      @impl true
      def init({router, socket}) do
        :inet.setopts(socket, active: true)
        {:ok, %{router: router, socket: socket}}
      end

      def start_link(router, socket) when is_atom(router) and is_port(socket) do
        GenServer.start_link(__MODULE__, {router, socket}, name: {:global, socket})
      end

      @impl true
      def handle_info({:tcp, socket, data}, state = %{router: router}) do
        Logger.info("Received message: #{inspect(data, limit: :infinity)}")
        handle_packet(socket, router, data)
        {:noreply, state}
      end

      def handle_info({:tcp_closed, socket}, state) do
        Logger.warn("Socket closed")
        {:noreply, state}
      end

      def handle_info({:tcp_error, socket, reason}, state) do
        Logger.error("Socket error: #{inspect(reason)}")
        {:noreply, state}
      end

      defp handle_packet(socket, router, data) do
        with {:ok, {packet_id, body}} <- parse_packet_id(data),
             {:ok, router = %Router{}} <- Router.route(router, packet_id),
             {:ok, schema} <- Parser.parse(router.schema, packet_id, body) do
          call_controller(router, socket, schema)
        end
      end

      defp parse_packet_id(<<first_byte::size(16)>> <> body) do
        packet_id = first_byte
        {packet_id, body}
      end

      defp call_controller(%Router{controller: controller, action: action}, socket, schema)
           when is_port(socket) and is_struct(schema) do
        case apply(controller, action, [schema]) do
          {:ok, response} ->
            :gen_tcp.send(socket, response)

          error ->
            Logger.error("Received from controller: #{inspect(error)}")
        end
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
    router = Listener.get_config(otp_app, mod, :router)

    do_start_listening(listen_socket, handler, router)
  end

  defp do_start_listening(listen_socket, handler, router)
       when is_port(listen_socket) and is_atom(handler) and is_atom(router) do
    with {:ok, client_socket} <- :gen_tcp.accept(listen_socket) do
      start_handler(client_socket, handler, router)
    end

    do_start_listening(listen_socket, handler, router)
  end

  defp start_handler(client_socket, handler, router)
       when is_port(client_socket) and is_atom(handler) and is_atom(router) do
    with {:module, _} <- Code.ensure_compiled(handler),
         {:module, _} <- Code.ensure_compiled(router),
         {:ok, pid} <- start_child(handler, router, client_socket) do
      :gen_tcp.controlling_process(client_socket, pid)
    else
      error ->
        Logger.error("Received error to start handler: #{inspect(error)}")
        error
    end
  end

  defp start_child(handler, router, client_socket) do
    DynamicSupervisor.start_child(Supervisor, %{
      id: client_socket,
      start: {handler, :start_link, [router, client_socket]},
      type: :worker
    })
  end
end
