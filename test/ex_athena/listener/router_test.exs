defmodule ExAthena.Listener.RouterTest do
  use ExUnit.Case

  alias ExAthena.Listener.Router

  describe "__route__/1" do
    test "returns an existing packet route" do
      assert {:ok,
              %Router{
                action: :create,
                controller: MyController,
                schema: MyPacket
              }} == MyRouter.__route__(0x64)
    end

    test "returns an error when packet hasn't been defined" do
      assert {:error, {:packet_id, :not_found}} == MyRouter.__route__(0x123)
    end
  end
end
