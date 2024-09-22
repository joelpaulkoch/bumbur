defmodule Bumbur do
  @moduledoc """
  Documentation for `Bumbur`.
  """

  use Application

  @server_node :server@localhost
  @client_node :client@localhost

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
        bumbur_error("too many arguments")

        bumbur_info("call without argument to start server, with single argument to ask bumbur")

        System.halt(1)
    end
  end

  defp start_server do
    case Node.start(@server_node, :shortnames) do
      {:ok, _pid} ->
        bumbur_info("starting server...")

        children = [
          {Nx.Serving, serving: build_serving(), name: Bumbur.Serving, batch_timeout: 100}
        ]

        Supervisor.start_link(children, strategy: :one_for_one)

      {:error, {:already_started, _node}} ->
        bumbur_error("this node already started")
        System.halt(1)

      {:error, _error} ->
        bumbur_error("server already started")
        System.halt(1)
    end
  end

  defp connect_and_ask(text) do
    bumbur_info("connecting to the server...")

    with {:ok, _pid} <- Node.start(@client_node, :shortnames),
         true <- Node.connect(@server_node) do
      bumbur_info("asking Bumbur...")

      :erpc.call(@server_node, Nx.Serving, :batched_run, [Bumbur.Serving, text])
    else
      {:error, _error} ->
        bumbur_error("could not start node")
        System.halt(1)

      false ->
        bumbur_error("could not connect to server")

        System.halt(1)
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
        |> Owl.Box.new(title: "Positive", padding: 1, horizontal_align: :center)

      %{label: "NEG"} ->
        """
        BUMBUR SAD
        SO NEGATIVE
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Negative", padding: 1, horizontal_align: :center)

      %{label: "NEU"} ->
        """
        BUMBUR SWITZERLAND
        SO NEUTRAL
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Neutral", padding: 1, horizontal_align: :center)
    end
  end

  defp bumbur_error(message) do
    "[Bumbur - ERROR] #{message}\n"
    |> Owl.Data.tag(:red)
    |> Owl.IO.puts()
  end

  defp bumbur_info(message) do
    "[Bumbur - INFO] #{message}\n"
    |> Owl.IO.puts()
  end
end
