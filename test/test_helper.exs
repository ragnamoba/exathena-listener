{:ok, _} = :application.ensure_all_started(:exathena_listener)

Code.require_file("support/x.ex", __DIR__)
Application.put_env(:exathena_listener, MyListener, port: 1234, handler: MyHandler)

ExUnit.start()
