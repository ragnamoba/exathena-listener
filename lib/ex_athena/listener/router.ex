defmodule ExAthena.Listener.Router do
  @moduledoc """
  Provides the packets DSL.

  Packets is a way trought ExAthena Listener know:

  A packet router must be implemented as a module of your
  application, as bellow:

  ```elixir
  defmodule MyApp.Router do
    use ExAthena.Listener.Router

    packet "0x67",
      schema: MyApp.Packet1,
      controller: MyApp.MyController,
      action: :authenticate

    packet "0x241",
      schema: MyApp.LoginPacket,
      controller: MyApp.AnotherController,
      action: :update
  end
  ```

  Each application using ExAthena Listener must
  have only one router.

  You need to inform ExAthena where is your Router
  using application configurations, as bellow:

  ```elixir
  config :exathena_listener,
    router: MyApp.Router
  ```

  For more details, see `packet/2`
  """

  alias ExAthena.Listener.Router.{
    InvalidRouteAction,
    InvalidRouteController,
    InvalidRouteSchema
  }

  @doc false
  defmacro __using__(_opts) do
    quote do
      @packets %{}

      @before_compile ExAthena.Listener.Router

      import ExAthena.Listener.Router
    end
  end

  @doc """
  Defines a `config` for a given `packet id`.

  ### Config fields

  * `schema` - Represents a `struct` using
  `ExAthena.Listener.Packet` which will be used to 
  represent any received packet;

  * `controller` - Represents a function
  which will process received packets.

  * `action` - Represents the function name
  from given controller.

  For more details, see the [module doc](#content).
  """
  defmacro packet(packet_id, opts) do
    quote bind_quoted: [packet_id: packet_id, opts: opts], location: :keep do
      schema = Keyword.fetch!(opts, :schema)
      controller = Keyword.fetch!(opts, :controller)
      action = Keyword.fetch!(opts, :action)

      with {:error, _} <- Code.ensure_compiled(schema) do
        raise InvalidRouteSchema,
          message: "Invalid schema! Schema must be a compiled"
      end

      with {:error, _} <- Code.ensure_compiled(controller) do
        raise InvalidRouteController,
          message: "Invalid controller! Controller must be a compiled"
      end

      with {:error, _} <- Module.defines?(controller, {actions, 2}) do
        raise InvalidRouteAction,
          message: "Invalid action! Action must be defined on given controller"
      end

      @packets Map.put(@packets, packet_id, %{
                 schema: schema,
                 controller: controller,
                 action: action
               })
    rescue
      _ ->
        raise ExAthena.Listener.Router.InvalidRoute,
          message: """
            Invalid route!

            A correct packet must includes a packet id, a schema,
            the packet controller and it's action to represent it,
            as bellow:

              packet "0x32",
                schema: MyApp.MessageSchema,
                controller: MyApp.MyController,
                action: :create

          """
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc false
      @spec __route__(String.t()) :: {:ok, map()} | {:error, {:packet_id, :not_found}}
      def __route__(packet_id) do
        case Map.get(@packets, packet_id) do
          nil ->
            {:error, {:packet_id, :not_found}}

          route = %{schema: _} ->
            {:ok, route}
        end
      end
    end
  end
end
