defmodule ParadigmInterop.Transforms.ParseSchemas do
  @moduledoc """
  Takes a Filesystem graph and produces a Universe graph where the appropriate files have been parsed and their ASTs converted to individual graphs.
  """
  @behaviour Paradigm.Transform
  alias Paradigm.Graph

  @impl true
  def transform(
        source_graph,
        target_graph,
        _opts
      ) do
    file_nodes = Graph.get_all_nodes_of_class(source_graph, "file")

    {:ok, result_graph} =
      file_nodes
      |> Enum.reduce({:ok, target_graph}, fn file_node_id, {:ok, acc_graph} ->
        {:ok, create_schema_graph(file_node_id, source_graph, acc_graph)}
      end)

    {:ok, result_graph}
  end

  defp create_schema_graph(file_node_id, source_graph, target_graph) do
    extension = Graph.get_node_data(source_graph, file_node_id, "extension", "")
    contents = Graph.get_node_data(source_graph, file_node_id, "contents", "")

    new_graph =
      case extension do
        ".thrift" ->
          ParadigmInterop.Thrift.create_thrift_graph(contents)

        ".proto" ->
          ParadigmInterop.Protobuf.create_protobuf_graph(file_node_id, contents)

        ".avsc" ->
          ParadigmInterop.Avro.create_avro_graph(contents)

        _ ->
          false
      end

    if new_graph do
      # TODO get hash id
      Graph.insert_node(
        target_graph,
        file_node_id,
        "registered_graph",
        %{
          "name" => file_node_id,
          "graph" => new_graph
        }
      )
    else
      target_graph
    end
  end
end
