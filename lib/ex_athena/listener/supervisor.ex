defmodule ExAthena.Listener.Supervisor do
  @moduledoc """
  TODO: Some module docs
  """
  use Supervisor

  @defaults [active: false, reuseaddr: true]

  @doc """
  Starts the listener supervisor.
  """
  def start_link(listener, otp_app, opts) do
    name = Keyword.get(opts, :name, listener)
    sup_opts = if name, do: [name: name], else: []
    Supervisor.start_link(__MODULE__, {name, listener, otp_app, opts}, sup_opts)
  end

  @doc """
  Retrieves the runtime configuration.
  """
  def runtime_config(type, listener, otp_app, opts) do
    initial_config = Application.get_env(otp_app, listener, [])

    merged_config =
      @defaults
      |> Keyword.merge(initial_config)
      |> Keyword.merge(opts)
      |> Keyword.put(:otp_app, otp_app)

    config =
      merged_config
      |> Keyword.put_new_lazy(:telemetry_prefix, fn -> telemetry_prefix(listener) end)

    listener_init(type, listener, config)
  end

  defp telemetry_prefix(listener) do
    listener
    |> Module.split()
    |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
  end

  defp listener_init(type, listener, config) do
    if Code.ensure_loaded?(listener) and function_exported?(listener, :init, 2) do
      listener.init(type, config)
    else
      {:ok, config}
    end
  end

  ## Callbacks

  @doc false
  def init({name, listener, otp_app, opts}) do
    # Normalize name to atom, ignore via/global names
    name = if is_atom(name), do: name, else: nil

    with {:ok, opts} <- runtime_config(:supervisor, listener, otp_app, opts),
         {:ok, socket} <- init_socket(opts) do
      # :telemetry.execute(
      #   [:exathena, :listener, :init],
      #   %{system_time: System.system_time()},
      #   %{listener: listener, opts: opts}
      # )
      {:ok, [socket: socket]}
    end
  end

  defp init_socket(opts) do
    {port, opts} = Keyword.pop(opts, :port)
    {_host, opts} = Keyword.pop(opts, :host)

    opts =
      opts
      |> Keyword.delete(:otp_app)
      |> Keyword.delete(:telemetry_prefix)

    opts = [:binary | opts]

    :gen_tcp.listen(port, opts)
  end

  def start_child({mod, fun, args}, name, meta) do
    with {:ok, pid} <- apply(mod, fun, args) do
      meta = Map.merge(meta, %{pid: pid})
      ExAthena.Listener.Registry.associate(self(), name, meta)

      {:ok, pid}
    end
  end
end
