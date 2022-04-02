defmodule MyHandler do
  use ExAthena.Listener.Handler, otp_app: :exathena_listener
end

defmodule MyListener do
  use ExAthena.Listener, otp_app: :exathena_listener
end

defmodule MyPacket do
  use ExAthena.Listener.Packet

  defpacket 0x64 do
    rule :username, :string, size: 16
    rule :password, :string, size: 32
  end
end

defmodule MyController do
  @doc false
  require Logger

  def create(%MyPacket{username: username, password: password}) do
    Logger.info("Username: #{inspect(username)}")
    Logger.info("Password: #{inspect(password)}")

    {:ok, <<100>>}
  end
end

defmodule MyRouter do
  use ExAthena.Listener.Router

  packet 0x64,
    schema: MyPacket,
    controller: MyController,
    action: :create
end
