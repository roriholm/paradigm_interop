defmodule ParadigmInterop.Transforms.ThriftToMetamodel do
  @behaviour Paradigm.Transform

  @type_mapping %{
    "bool" => "boolean",
    "byte" => "integer",
    "i8" => "integer",
    "i16" => "integer",
    "i32" => "integer",
    "i64" => "integer",
    "double" => "float",
    "string" => "string",
    "binary" => "string",
    "uuid" => "string"
  }

  @impl true
  def transform(source_graph, target_graph, _opts) do
    # Build union type mapping first
    union_node_ids = Paradigm.Graph.get_all_nodes_of_class(source_graph, "union")
    union_mapping = Enum.reduce(union_node_ids, %{}, &build_union_mapping(&1, &2, source_graph))

    # Process unions as abstract classes
    union_result =
      Enum.reduce(union_node_ids, {:ok, target_graph}, fn node_id, {:ok, acc} ->
        convert_union_node(node_id, acc, source_graph)
      end)

    # Then process structs with union mapping
    case union_result do
      {:ok, graph_with_unions} ->
        struct_node_ids = Paradigm.Graph.get_all_nodes_of_class(source_graph, "struct")

        Enum.reduce(struct_node_ids, {:ok, graph_with_unions}, fn node_id, {:ok, acc} ->
          convert_type_node(node_id, acc, source_graph, union_mapping)
        end)

      error ->
        error
    end
  end

  defp build_union_mapping(node_id, acc, graph) do
    fields = Paradigm.Graph.get_node_data(graph, node_id, "fields", [])

    Enum.reduce(fields, acc, fn field_id, union_acc ->
      field_type = Paradigm.Graph.get_node_data(graph, field_id, "type")

      case Map.get(union_acc, field_type) do
        nil -> Map.put(union_acc, field_type, [node_id])
        existing -> Map.put(union_acc, field_type, [node_id | existing])
      end
    end)
  end

  defp convert_union_node(node_id, acc, graph) do
    class_id = to_string(node_id)
    class_name = Paradigm.Graph.get_node_data(graph, node_id, "name")

    result =
      Paradigm.Graph.insert_node(acc, class_id, "class", %{
        "name" => class_name,
        "is_abstract" => true,
        "owned_attributes" => [],
        "super_classes" => []
      })

    {:ok, result}
  end

  defp convert_type_node(node_id, acc, graph, union_mapping) do
    class_id = to_string(node_id)
    class_name = Paradigm.Graph.get_node_data(graph, node_id, "name")

    fields = Paradigm.Graph.get_node_data(graph, node_id, "fields", [])

    case convert_fields(fields, acc, graph) do
      {:ok, {acc_with_props, properties}} ->
        result =
          Paradigm.Graph.insert_node(acc_with_props, class_id, "class", %{
            "name" => class_name,
            "is_abstract" => false,
            "owned_attributes" => properties,
            "super_classes" => Map.get(union_mapping, class_id, [])
          })

        {:ok, result}

      error ->
        error
    end
  end

  defp convert_fields(fields, acc, graph) do
    Enum.reduce(fields, {:ok, {acc, []}}, fn field_id, {:ok, {current_acc, properties}} ->
      convert_field(field_id, current_acc, properties, graph)
    end)
  end

  defp convert_field(field_id, acc, properties, graph) do
    property_id = to_string(field_id)

    field_data = %{
      name: Paradigm.Graph.get_node_data(graph, field_id, "name"),
      type: Paradigm.Graph.get_node_data(graph, field_id, "type"),
      required: Paradigm.Graph.get_node_data(graph, field_id, "required"),
      is_list: Paradigm.Graph.get_node_data(graph, field_id, "is_list"),
      default: Paradigm.Graph.get_node_data(graph, field_id, "default")
    }

    property_attrs = create_property_attrs(field_data)
    result_acc = Paradigm.Graph.insert_node(acc, property_id, "property", property_attrs)
    {:ok, {result_acc, properties ++ [property_id]}}
  end

  defp create_property_attrs(%{
         name: name,
         type: type,
         required: required,
         is_list: is_list,
         default: default
       }) do
    %{
      "name" => name,
      "type" => convert_type(type),
      "is_ordered" => is_list,
      "is_composite" => is_list,
      "lower_bound" => if(required, do: 1, else: 0),
      "upper_bound" => if(is_list, do: :infinity, else: 1),
      "default_value" => default
    }
  end

  defp convert_type(type) do
    Map.get(@type_mapping, type, type)
  end
end
