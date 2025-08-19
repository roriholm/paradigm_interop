defmodule ParadigmInterop.ParseSchemas do
  @moduledoc """
  Takes a Filesystem graph and produces a Schema graph where the appropriate files have been parsed into the correct built-in structures.
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
        case create_schema_document(file_node_id, source_graph, acc_graph) do
          {:ok, updated_graph} -> {:ok, updated_graph}
          # Not a schema file, skip
          {:skip} -> {:ok, acc_graph}
        end
      end)

    {:ok, result_graph}
  end

  defp create_schema_document(file_node_id, source_graph, target_graph) do
    extension = source_graph.impl.get_node_data(source_graph.data, file_node_id, "extension", "")

    case extension do
      ".thrift" ->
        create_thrift_document(file_node_id, source_graph, target_graph)

      ".proto" ->
        create_protobuf_document(file_node_id, source_graph, target_graph)

      ".avsc" ->
        create_avro_document(file_node_id, source_graph, target_graph)

      _ ->
        # Not a schema file extension we recognize
        {:skip}
    end
  end

  defp create_thrift_document(file_node_id, source_graph, target_graph) do
    contents = Graph.get_node_data(source_graph, file_node_id, "contents", "")

    {:ok, thrift_ast} = Thrift.Parser.parse_string(contents)

    updated_graph =
      Graph.insert_node(
        target_graph,
        file_node_id,
        "thrift_document",
        %{
          source_path: file_node_id,
          parse_metadata: generate_parse_metadata(),
          thrift_ast: thrift_ast
        }
      )

    {:ok, updated_graph}
  end

  defp create_protobuf_document(file_node_id, source_graph, target_graph) do
    contents = Graph.get_node_data(source_graph, file_node_id, "contents", "")

    {:ok, desc_contents} = compile_proto_to_desc(file_node_id, contents)
    {:ok, protobuf_definition} = Protox.Parse.parse(desc_contents)

    updated_graph =
      Graph.insert_node(
        target_graph,
        file_node_id,
        "protobuf_document",
        %{
          source_path: file_node_id,
          parse_metadata: generate_parse_metadata(),
          protobuf_definition: protobuf_definition
        }
      )

    {:ok, updated_graph}
  end

  defp compile_proto_to_desc(proto_path, content) do
    # Create temp directory for both input and output
    temp_dir = System.tmp_dir!()
    temp_proto_path = Path.join(temp_dir, Path.basename(proto_path))
    desc_filename = Path.basename(proto_path, ".proto") <> ".desc"
    desc_path = Path.join(temp_dir, desc_filename)

    with :ok <- File.write(temp_proto_path, content),
         true <- File.exists?(temp_proto_path),
         {_output, 0} <-
           System.cmd("protoc", [
             "--proto_path=#{temp_dir}",
             "--descriptor_set_out=#{desc_path}",
             "--include_imports",
             Path.basename(proto_path)
           ]) do
      File.read(desc_path)
    else
      {:error, reason} ->
        # Clean up on error
        File.rm(temp_proto_path)
        {:error, "Failed to write temp proto file: #{inspect(reason)}"}

      {error_output, exit_code} ->
        # Clean up on error
        File.rm(temp_proto_path)
        {:error, "protoc failed with exit code #{exit_code}: #{error_output}"}
    end
  rescue
    e in ErlangError ->
      {:error, "protoc command not found: #{inspect(e)}"}
  end

  defp create_avro_document(file_node_id, source_graph, target_graph) do
    contents = Graph.get_node_data(source_graph, file_node_id, "contents", "")

    {:ok, avro_schema} = AvroEx.decode_schema(contents)

    updated_graph =
      Graph.insert_node(
        target_graph,
        file_node_id,
        "avro_document",
        %{
          source_path: file_node_id,
          parse_metadata: generate_parse_metadata(),
          avro_schema: avro_schema
        }
      )

    {:ok, updated_graph}
  end

  defp generate_parse_metadata do
    %{
      parsed_at: DateTime.utc_now(),
      parser_version: "1.0.0"
    }
  end
end
