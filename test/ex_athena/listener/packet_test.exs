defmodule ExAthena.Listener.PacketTest do
  use ExUnit.Case

  describe "__packet__/1" do
    test "returns the packet id" do
      assert 0x64 == MyPacket.__packet__(:id)
    end

    test "returns the list of struct fields from packet" do
      assert [:id, :username, :password] == MyPacket.__packet__(:struct_fields)
    end

    test "returns the list of rules from packet" do
      assert [
               %ExAthena.Listener.Rule{
                 name: :packet_id,
                 opts: [size: 32],
                 type: :hexadecimal
               },
               %ExAthena.Listener.Rule{
                 name: :username,
                 opts: [size: 16],
                 type: :string
               },
               %ExAthena.Listener.Rule{
                 name: :password,
                 opts: [size: 32],
                 type: :string
               }
             ] == MyPacket.__packet__(:rules)
    end
  end
end
