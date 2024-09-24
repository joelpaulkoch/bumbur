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

      Nx.Serving.batched_run({:distributed, Bumbur.Serving}, text)
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
    {:ok, model} = Bumblebee.load_model({:hf, "facebook/bart-large-mnli", offline: true})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "facebook/bart-large-mnli", offline: true})

    labels = ["something an owl would say", "something a cat would say"]

    Bumblebee.Text.zero_shot_classification(model, tokenizer, labels)
  end

  defp visualize_predictions(predictions) do
    case hd(predictions) do
      %{label: "something an owl would say"} ->
        """
           ,_, 
          {o,o}
          /)  )
        ---"-"--
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Owl", padding: 1, horizontal_align: :center)

      %{label: "something a cat would say"} ->
        """
         /_/\\ 
        ( o.o )
         > ^ <
        """
        |> String.trim_trailing()
        |> Owl.Box.new(title: "Cat", padding: 1, horizontal_align: :center)

      _ ->
        Owl.Data.tag("unknown prediction", :red)
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
