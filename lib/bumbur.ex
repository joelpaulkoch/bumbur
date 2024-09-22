defmodule Bumbur do
  @moduledoc """
  Documentation for `Bumbur`.
  """

  use Application

  def start(_, _) do
    # Returning `{:ok, pid}` will prevent the application from halting.
    # Use System.halt(exit_code) to terminate the VM when required

    args = Burrito.Util.Args.argv()

    case args do
      [] ->
        start_server()

      [text] ->
        %{predictions: predictions} = connect_and_ask(text)

        predictions
        |> visualize_predictions()
        |> Owl.IO.puts()

        System.halt(0)

      _ ->
        """
        [Bumbur] error: too many arguments
        call without arguments to start bumbur
        call with a single argument to ask bumbur about your text
        """
        |> Owl.IO.puts()

        System.halt(1)
    end
  end

  defp start_server do
    case Node.start(:server@localhost, :shortnames) do
      {:ok, _pid} ->
        Owl.IO.puts("[Bumbur] starting server...\n")

        children = [
          {Nx.Serving, serving: build_serving(), name: Bumbur.Serving, batch_timeout: 100}
        ]

        Supervisor.start_link(children, strategy: :one_for_one)

      {:error, {:already_started, _node}} ->
        Owl.IO.puts("[Bumbur] error: this node already started")
        System.halt(1)

      {:error, _error} ->
        Owl.IO.puts("[Bumbur] error: server already started")
        System.halt(1)
    end
  end

  defp connect_and_ask(text) do
    Owl.IO.puts("[Bumbur] connecting to the server...\n")

    with {:ok, _pid} <- Node.start(:client@localhost, :shortnames),
         true <- Node.connect(:server@localhost) do
      Owl.IO.puts("[Bumbur] asking Bumbur\n")

      :erpc.call(:server@localhost, Nx.Serving, :batched_run, [Bumbur.Serving, text])
    end
  end

  def build_serving do
    {:ok, bertweet} =
      Bumblebee.load_model({:hf, "finiteautomata/bertweet-base-sentiment-analysis"})

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "vinai/bertweet-base"})

    Bumblebee.Text.text_classification(bertweet, tokenizer)
  end

  defp visualize_predictions(predictions) do
    case hd(predictions) do
      %{label: "POS"} ->
        """
        BUMBUR HAPPY
        SO POSITIVE
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Positive")

      %{label: "NEG"} ->
        """
        BUMBUR SAD
        SO NEGATIVE
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Negative")

      %{label: "NEU"} ->
        """
        BUMBUR SWITZERLAND
        SO NEUTRAL
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Neutral")
    end
  end
end
