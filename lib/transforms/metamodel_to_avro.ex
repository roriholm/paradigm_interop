defmodule ParadigmInterop.Transforms.MetamodelToAvro do
  @behaviour Paradigm.Transform

  @type_mappings %{
    "integer" => "int",
    "void" => "null"
  }

  @impl true
  def transform(source_graph, target_graph, _opts) do
    try do
      do_transform(source_graph, target_graph)
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp do_transform(source_graph, target_graph) do
    with {:ok, graph_with_classes} <- transform_classes(source_graph, target_graph),
         {:ok, graph_with_enums} <- transform_enumerations(source_graph, graph_with_classes) do
      {:ok, graph_with_enums}
    end
  end

  defp transform_classes(source_graph, target_graph) do
    class_nodes = Paradigm.Graph.get_all_nodes_of_class(source_graph, "class")

    Enum.reduce(class_nodes, {:ok, target_graph}, fn node_id, {:ok, acc} ->
      process_class(node_id, source_graph, acc)
    end)
  end

  defp process_class(id, source_graph, target_graph) do
    fields = Paradigm.Graph.get_node_data(source_graph, id, "owned_attributes", [])

    with {:ok, graph_with_record} <- add_record_node(target_graph, id, source_graph, fields),
         {:ok, graph_with_fields} <- add_field_nodes(graph_with_record, fields, source_graph) do
      {:ok, graph_with_fields}
    end
  end

  defp add_record_node(target_graph, id, source_graph, fields) do
    name = Paradigm.Graph.get_node_data(source_graph, id, "name", nil)

    record_data = %{
      "name" => name,
      "aliases" => [],
      "fields" => fields,
      "doc" => nil,
      "namespace" => nil
    }

    {:ok, Paradigm.Graph.insert_node(target_graph, id, "record", record_data)}
  end

  defp add_field_nodes(target_graph, fields, source_graph) do
    Enum.reduce(fields, {:ok, target_graph}, fn prop_id, {:ok, acc} ->
      name = Paradigm.Graph.get_node_data(source_graph, prop_id, "name", nil)
      type = get_property_type(Paradigm.Graph.get_node_data(source_graph, prop_id, "type", nil))
      upper_bound = Paradigm.Graph.get_node_data(source_graph, prop_id, "upper_bound", 1)
      default = Paradigm.Graph.get_node_data(source_graph, prop_id, "default_value", nil)
      is_array = upper_bound == :infinity or upper_bound > 1

      if is_array do
        array_type_name = "#{type}_array"

        array_data = %{
          "name" => array_type_name,
          "items" => type
        }

        field_data = %{
          "name" => name,
          "type" => array_type_name,
          "aliases" => [],
          "default" => default,
          "doc" => nil
        }

        acc_with_array = Paradigm.Graph.insert_node(acc, array_type_name, "array", array_data)
        {:ok, Paradigm.Graph.insert_node(acc_with_array, prop_id, "field", field_data)}
      else
        field_data = %{
          "name" => name,
          "type" => type,
          "aliases" => [],
          "default" => default,
          "doc" => nil
        }

        {:ok, Paradigm.Graph.insert_node(acc, prop_id, "field", field_data)}
      end
    end)
  end

  defp transform_enumerations(source_graph, target_graph) do
    enum_nodes = Paradigm.Graph.get_all_nodes_of_class(source_graph, "enumeration")

    Enum.reduce(enum_nodes, {:ok, target_graph}, fn node_id, {:ok, acc} ->
      add_enum_node(node_id, source_graph, acc)
    end)
  end

  defp add_enum_node(id, source_graph, target_graph) do
    name = Paradigm.Graph.get_node_data(source_graph, id, "name", nil)
    literals = Paradigm.Graph.get_node_data(source_graph, id, "literals", [])

    enum_data = %{
      "name" => name,
      "namespace" => "metamodel",
      "symbols" => get_enum_symbols(source_graph, literals)
    }

    {:ok, Paradigm.Graph.insert_node(target_graph, "enum_#{id}", "enum", enum_data)}
  end

  defp get_enum_symbols(graph, literal_ids) when is_list(literal_ids) do
    Enum.map(literal_ids, &Paradigm.Graph.get_node_data(graph, &1, "name", nil))
  end

  defp get_enum_symbols(_, _), do: []

  defp get_property_type(type) do
    Map.get(@type_mappings, type, type)
  end
end
