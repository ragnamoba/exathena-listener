defmodule ExAthena.Listener.Field do
  defstruct name: nil, type: nil, opts: []
end

defmodule ExAthena.Listener.Packet do
  @moduledoc false

  alias ExAthena.Listener.Field

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      import ExAthena.Listener.Packet,
        only: [defpacket: 2]

      @packet_id nil

      Module.register_attribute(__MODULE__, :rules, accumulate: true)
      Module.register_attribute(__MODULE__, :fields, accumulate: true)

      @before_compile ExAthena.Listener.Packet

      import ExAthena.Listener.Packet
    end
  end

  @doc false
  defmacro defpacket(name, do: block) do
    quote do
      @packet_id unquote(name)
      unquote(block)
    end
  end

  defmacro field(name, type, size: size) do
    quote bind_quoted: [name: name, type: type, size: size] do
      field = %Field{name: name, type: type, opts: [size: size]}

      [name | @fields]
      [field | @rules]
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      defstruct @fields
    end
  end
end
