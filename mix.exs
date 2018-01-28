defmodule IElixir.Mixfile do
  use Mix.Project

  @version "0.9.7"

  def project do
    [app: :ielixir,
     version: @version,
     source_url: "https://github.com/pprzetacznik/IElixir",
     name: "IElixir",
     elixir: ">= 1.1.0 and < 1.7.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: """
     Jupyter's kernel for Elixir programming language
     """,
     package: package(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [mod: {IElixir, []},
     applications: [:logger, :iex, :sqlite_ecto, :ecto, :chumak, :poison, :uuid]]
  end

  defp deps do
    [{:chumak, "~> 1.2"},
     {:poison, "~> 1.0"},
     {:uuid, github: "okeuday/uuid"},

     {:sqlite_ecto, "~> 1.1.0"},

     # Docs dependencies
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.7", only: :docs},
     {:inch_ex, "0.4.0", only: :docs},

     # Test dependencies
     {:excoveralls, "~> 0.3.11", only: :test}]
  end

  defp package do
     [files: ["config", "lib", "priv", "resources", "mix.exs", "README.md", "LICENSE", "install_script.sh", "start_script.sh", ".travis.yml"],
     maintainers: ["Piotr Przetacznik"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/pprzetacznik/ielixir",
              "Docs" => "http://hexdocs.pm/ielixir/"}]
  end
end
