defmodule BumbBur do
  @moduledoc """
  Documentation for `BumbBur`.
  """

  use Application

  def start(_, _) do
    # Returning `{:ok, pid}` will prevent the application from halting.
    # Use System.halt(exit_code) to terminate the VM when required

    args = Burrito.Util.Args.argv()

    dbg(args)

    case args do
      [] ->
        start_server()

      [text] ->
        %{predictions: [prediction | _]} = connect_and_ask(text)

        IO.puts(prediction.label)

        System.halt(0)
    end
  end

  defp start_server do
    case Node.start(:server@localhost, :shortnames) do
      {:ok, _pid} ->
        dbg("starting server")

        children = [
          {Nx.Serving, serving: build_serving(), name: BumbBur.Serving, batch_timeout: 100}
        ]

        Supervisor.start_link(children, strategy: :one_for_one)

      {:error, {:already_started, _node}} ->
        dbg("already started")
        System.halt(1)
    end
  end

  defp connect_and_ask(text) do
    dbg("connecting and asking")

    with {:ok, _pid} <- Node.start(:client, :shortnames),
         true <- Node.connect(:server@localhost) do
      result =
        :erpc.call(:server@localhost, Nx.Serving, :batched_run, [BumbBur.Serving, text])
    end
  end

  def build_serving do
    {:ok, bertweet} =
      Bumblebee.load_model({:hf, "finiteautomata/bertweet-base-sentiment-analysis"})

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "vinai/bertweet-base"})

    Bumblebee.Text.text_classification(bertweet, tokenizer)
  end
end
