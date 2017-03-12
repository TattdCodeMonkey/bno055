defmodule Bno055.Mixfile do
  use Mix.Project

  def project do
    [app: :bno055,
     version: "1.0.0",
     elixir: ">= 1.0.0 and < 2.0.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description(),
     package: package(),
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
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Rodney Norris"],
      licenses: ["MIT"],
      links:  %{"GitHub" => "https://github.com/TattdCodeMonkey/bno055"}
    ]
  end

  defp deps do
    []
  end
end
