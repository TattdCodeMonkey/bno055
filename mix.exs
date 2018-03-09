defmodule Bno055.Mixfile do
  use Mix.Project

  @github_url "https://github.com/TattdCodeMonkey/bno055"

  def project do
    [
      app: :bno055,
      version: "1.0.0",
      elixir: ">= 1.0.0 and < 2.0.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      source_url: @github_url,
      homepage_url: @github_url,
      files: ~w(mix.exs lib README.md LICENSE CHANGELOG.md),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test, 
        "coveralls.detail": :test, 
        "coveralls.post": :test, 
        "coveralls.html": :test
      ]
   ]
  end

  def application do
    [
      applications: [
        :logger
      ]
    ]
  end

  def description, do: """

  """

  def package do
    [      
      maintainers: ["Rodney Norris"],
      licenses: ["MIT"],
      links:  %{"GitHub" => @github_url}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false},     
    ]
  end
end
