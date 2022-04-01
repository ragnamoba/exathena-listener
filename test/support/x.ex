defmodule MyHandler do
  use ExAthena.Listener.Handler, otp_app: :exathena_listener
end

defmodule MyListener do
  use ExAthena.Listener, otp_app: :exathena_listener
end

defmodule LoginPacket do
  use ExAthena.Listener.Packet

  defpacket "0x64" do
    field :login, :string, size: 16
    field :password, :string, size: 32
  end
end
