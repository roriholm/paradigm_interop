defmodule ParadigmInterop.Thrift do
  def create_thrift_graph(contents) do
    {:ok, %Thrift.AST.Schema{structs: structs} = schema} = Thrift.Parser.parse_string(contents)
    IO.inspect(schema)
    false
  end

  defp create_thrift_schema_graph(thrift_ast) do
    graph = Paradigm.Graph.MapGraph.new()

    thrift_ast.structs
    |> Enum.reduce(graph, fn {struct_name, struct}, acc_graph ->
      # Create field nodes for this struct
      field_nodes =
        struct.fields
        |> Enum.map(fn field ->
          field_id = "#{struct_name}_#{field.name}"

          field_attrs = %{
            "name" => Atom.to_string(field.name),
            "type" => field.type |> type_to_string(),
            "required" => field.required == :required,
            "default" => field.default,
            "is_list" => type_is_list(field.type)
          }

          {field_id, "field", field_attrs}
        end)

      # Create struct node
      field_ids = Enum.map(field_nodes, fn {field_id, _, _} -> field_id end)

      struct_attrs = %{
        "name" => "#{struct_name}",
        "fields" => field_ids
      }

      # Insert struct node first
      graph_with_struct = Graph.insert_node(acc_graph, struct_name, "struct", struct_attrs)

      # Insert field nodes one by one
      field_nodes
      |> Enum.reduce(graph_with_struct, fn {field_id, field_class, field_attrs}, graph_acc ->
        Graph.insert_node(graph_acc, field_id, field_class, field_attrs)
      end)
    end)
  end

  defp type_to_string(type) do
    case type do
      {:list, inner_type} -> type_to_string(inner_type)
      %Thrift.AST.TypeRef{referenced_type: type} -> Atom.to_string(type)
      type when is_atom(type) -> Atom.to_string(type)
      _ -> "unknown"
    end
  end

  defp type_is_list({:list, _}), do: true
  defp type_is_list(_), do: false
end
