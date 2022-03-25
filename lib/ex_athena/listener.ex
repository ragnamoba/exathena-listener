defmodule ExAthena.Listener do
  @moduledoc """
  TODO: Some module docs
  """

  @doc """
  TODO: Some macro docs
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour ExAthena.Listener

      @using_options opts
      @otp_app Keyword.fetch!(opts, :otp_app)
      @default_dynamic_listener opts[:default_dynamic_listener] || __MODULE__

      def config do
        {:ok, config} =
          ExAthena.Listener.Supervisor.runtime_config(:runtime, __MODULE__, @otp_app, [])

        config
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        opts = Keyword.merge(opts, @using_options)
        ExAthena.Listener.Supervisor.start_link(__MODULE__, @otp_app, opts)
      end

      @compile {:inline, get_dynamic_listener: 0}

      def get_dynamic_listener do
        Process.get({__MODULE__, :dynamic_listener}, @default_dynamic_listener)
      end

      def put_dynamic_listener(dynamic) when is_atom(dynamic) or is_pid(dynamic) do
        Process.put({__MODULE__, :dynamic_listener}, dynamic) || @default_dynamic_listener
      end

      def stop(timeout \\ 5000) do
        Supervisor.stop(get_dynamic_listener(), :normal, timeout)
      end
    end
  end
end
