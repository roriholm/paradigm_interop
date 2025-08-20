defmodule ParadigmInterop.Protobuf do
  def create_protobuf_graph(contents) do
    {:ok, desc_contents} = compile_proto_to_desc(contents)

    {:ok, %Protox.Definition{enums_schemas: _protobuf_enums, messages_schemas: protobuf_messages}} =
      Protox.Parse.parse(desc_contents)

    baseline_graph = Paradigm.Graph.MapGraph.new() |> populate_primitives()

    protobuf_messages
    |> Enum.reduce(
      baseline_graph,
      fn {id, %Protox.MessageSchema{name: name, fields: fields}}, acc_graph ->
        clean_name = name |> to_string() |> String.replace_prefix("Elixir.", "")

        field_names =
          fields
          |> Enum.map(fn {field_id, _field} ->
            %Paradigm.Graph.Node.Ref{id: "#{clean_name}_#{field_id}"}
          end)

        acc_graph
        |> Paradigm.Graph.insert_node(id, "message", %{name: clean_name, fields: field_names})
        |> insert_fields(clean_name, fields)
      end
    )
  end

  defp populate_primitives(graph) do
    ["double", "float", "int32", "int64", "bool", "string"]
    |> Enum.reduce(graph, fn prim, acc ->
      Paradigm.Graph.insert_node(acc, prim, "primitive", %{name: prim})
    end)
  end

  defp insert_fields(graph, message_name, fields) do
    Enum.reduce(fields, graph, fn {id, field}, acc ->
      field_id = "#{message_name}_#{field.name}"

      Paradigm.Graph.insert_node(acc, field_id, "field", %{
        name: to_string(field.name),
        type: convert_type(field.type),
        tag: field.tag
      })
    end)
  end

  defp convert_type({:message, message_id}), do: %Paradigm.Graph.Node.Ref{id: message_id}
  defp convert_type(atom), do: %Paradigm.Graph.Node.Ref{id: to_string(atom)}

  defp compile_proto_to_desc(content) do
    # Create temp directory for both input and output
    proto_path = "tmp.proto"
    temp_dir = System.tmp_dir!()
    temp_proto_path = Path.join(temp_dir, proto_path)
    desc_filename = Path.basename(proto_path, ".proto") <> ".desc"
    desc_path = Path.join(temp_dir, desc_filename)

    with :ok <- File.write(temp_proto_path, content),
         true <- File.exists?(temp_proto_path),
         {_output, 0} <-
           System.cmd("protoc", [
             "--proto_path=#{temp_dir}",
             "--descriptor_set_out=#{desc_path}",
             "--include_imports",
             proto_path
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
end
