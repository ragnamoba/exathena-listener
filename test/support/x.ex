defmodule MyHandler do
  use ExAthena.Listener.Handler, otp_app: :exathena_listener
end

defmodule MyListener do
  use ExAthena.Listener, otp_app: :exathena_listener
end
