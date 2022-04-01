defmodule ExAthena.Listener.MixProject do
  use Mix.Project

  def project do
    [
      app: :exathena_listener,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: dialyzer()
    ] ++ hex()
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:ecto, :ex_machina, :timex, :quinn, :tesla],
      ignore_warnings: ".dialyzerignore"
    ]
  end

  defp hex do
    [
      name: "ExAthena Listener",
      description: "ExAthena Listener",
      package: [
        name: "exathena_listener",
        maintainers: ["Alexandre de Souza"],
        licenses: ["MIT"],
        links: %{"Github" => "https://github.com/ragnamoba/exathena-listener"}
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:runtime_tools, :logger, :telemetry],
      mod: {ExAthena.Listener, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.13"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:telemetry, "~> 1.0"}
    ]
  end
end
