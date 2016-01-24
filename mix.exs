defmodule Bno055.Mixfile do
  use Mix.Project

  def project do
    [app: :bno055,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps ++ deps(operating_system),
     package: package()
   ]
  end

  def application do
    [
      applications: [:logger],
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
      {:mon_handler, "~>1.0"},
    ]
  end

  defp deps("Linux") do
    [
      {:elixir_ale, "~>0.4"}
    ]
  end

  defp deps(_), do: []

  def operating_system do
    case Application.get_env(:bno055, :operating_system) do
      nil ->
        Port.open({:spawn, "uname"}, [])

        os = receive do
          {_port, {:data, result}} -> result
          error -> error
        end

        result = os
        |> to_string
        |> String.replace("\n", "")

        :application.set_env(:bno055, :operating_system, result)

        result
      os_value -> os_value
    end
  end
end
