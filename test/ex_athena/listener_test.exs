defmodule ExAthena.ListenerTest do
  use ExUnit.Case

  describe "start_link/2" do
    defmodule GenServerTest do
      @moduledoc false
      use ExAthena.Listener, otp_app: :exathena_listener, host: "localhost", port: 6900
    end

    setup do
      {:ok, pid} = GenServerTest.start_link()

      {:ok, pid: pid}
    end

    test "starts the packet listener", %{pid: pid} do
      gen_server_test = GenServer.whereis(GenServerTest)

      assert pid
      assert gen_server_test
      assert gen_server_test == pid
    end
  end
end
