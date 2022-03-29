defmodule ExAthena.ListenerTest do
  use ExUnit.Case

  defmodule Listener do
    @moduledoc false
    use ExAthena.Listener, otp_app: :exathena_listener

    assert @otp_app == :exathena_listener
  end

  test "start_link/0 should returns the sockerl gen server" do
    start_supervised!(Listener)
  end
end
