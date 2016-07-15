defmodule Bno055.Mixfile do
  use Mix.Project

  def project do
    [app: :bno055,
     version: "0.1.1",
     elixir: ">= 1.0.0 and < 2.0.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package,
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

  def description, do: """
    OTP application for reading the BNO-055 absolute orientation sensor.

    Euler angles are read at 20hz and published to a configured local `gproc` property.
  """

  def package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Rodney Norris"],
      licenses: ["MIT"],
      links:  %{"GitHub" => "https://github.com/TattdCodeMonkey/bno055"}
    ]
  end

  defp deps do
    [
      {:gproc, "~>0.5"}
    ] ++ add_deps(Mix.env)
  end

  defp add_deps(:test), do: []
  defp add_deps(_), do: [{:elixir_ale, "~>0.4", only: [:dev, :prod]}]
end
