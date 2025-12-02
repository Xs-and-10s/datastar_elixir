defmodule Datastar.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Xs-and-10s/datastar_elixir"

  def project do
    [
      app: :datastar_ex,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "DatastarEx",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:plug, "~> 1.15", optional: true},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    An Elixir SDK for the Datastar web framework. Provides server-sent event (SSE)
    utilities for real-time DOM manipulation, state synchronization, and script execution.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Datastar" => "https://data-star.dev"
      },
      maintainers: ["mmanley"]
    ]
  end

  defp docs do
    [
      main: "Datastar",
      extras: ["README.md", "LICENSE"]
    ]
  end
end
