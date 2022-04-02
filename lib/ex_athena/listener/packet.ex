defmodule ExAthena.Listener.Packet do
  @moduledoc false

  alias ExAthena.Listener.Rule

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      import ExAthena.Listener.Packet,
        only: [defpacket: 2]

      @packet_id nil

      Module.register_attribute(__MODULE__, :rules, accumulate: true)
      Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)

      @before_compile ExAthena.Listener.Packet

      import ExAthena.Listener.Packet
    end
  end

  @doc false
  defmacro defpacket(name, do: block) do
    quote do
      @packet_id unquote(name)
      rule = %Rule{name: :packet_id, type: :hexadecimal, opts: [size: 8]}

      Module.put_attribute(__MODULE__, :struct_fields, {:id, @packet_id})
      Module.put_attribute(__MODULE__, :rules, rule)

      unquote(block)
    end
  end

  defmacro rule(name, type, size: size) do
    quote bind_quoted: [name: name, type: type, size: size] do
      rule = %Rule{name: name, type: type, opts: [size: size]}
      default_value = nil

      Module.put_attribute(__MODULE__, :struct_fields, {name, default_value})
      Module.put_attribute(__MODULE__, :rules, rule)
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      defstruct @struct_fields

      @doc false
      def __packet__(:id), do: @packet_id

      def __packet__(:struct_fields) do
        @struct_fields
        |> Keyword.keys()
        |> Enum.reverse()
      end

      def __packet__(:rules), do: Enum.reverse(@rules)
    end
  end
end
