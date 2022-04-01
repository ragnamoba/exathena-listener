defmodule ExAthena.ListenerTest do
  use ExUnit.Case

  alias ExAthena.Listener

  test "start_link/0 should returns the listener genserver" do
    assert {:ok, _pid} = MyListener.start_link()
  end

  describe "get_config/3" do
    test "gets the handler from config" do
      assert Listener.get_config(:exathena_listener, MyListener, :handler) == MyHandler
    end

    test "gets nil from unknown key" do
      refute Listener.get_config(:exathena_listener, MyListener, :foo)
    end
  end
end
