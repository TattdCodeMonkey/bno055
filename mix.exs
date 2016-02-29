defmodule Bno055.Mixfile do
  use Mix.Project

  def project do
    [app: :bno055,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package()
   ]
  end

  def application do
    [
      applications: [
        :logger,
        :gproc
      ],
      registered: [:bno055],
      mod: {BNO055, []}
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Rodney Norris"],
      licenses: ["MIT"],
      links: []
    ]
  end

  defp deps do
    [
      {:gproc, "~>0.5"},
      {:mon_handler, "~>1.0"},
      {:elixir_ale, "~>0.4", only: [:dev, :prod]},
    ]
  end
end
