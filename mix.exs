defmodule BumbBur.MixProject do
  use Mix.Project

  def project do
    [
      app: :bumb_bur,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BumbBur, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:owl, "~> 0.11"},
      {:bumblebee, "~> 0.5.0"},
      {:nx, "~> 0.7.0"},
      {:exla, "~> 0.7.0"},
      {:axon, "~> 0.6.1"}
    ]
  end

  def releases do
    [
      bumb_bur: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :aarch64]
          ]
        ]
      ]
    ]
  end
end
