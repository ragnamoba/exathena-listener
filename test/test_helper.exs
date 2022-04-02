{:ok, _} = :application.ensure_all_started(:exathena_listener)

Code.require_file("support/dummy_app.ex", __DIR__)
Application.put_env(:exathena_listener, MyListener, port: 1234, router: MyRouter, handler: MyHandler)

ExUnit.start()
