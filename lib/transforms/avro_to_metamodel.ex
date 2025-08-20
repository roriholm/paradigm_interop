defmodule ParadigmInterop.Transforms.AvroToMetamodel do
  alias Paradigm.Graph.Node
  @behaviour Paradigm.Transform

  @type_mapping %{
    "null" => "null",
    "boolean" => "boolean",
    "int" => "integer",
    "long" => "integer",
    "float" => "float",
    "double" => "double",
    "bytes" => "string",
    "string" => "string"
  }

  @impl true
  def transform(source_graph, target_graph, _opts) do
    # Get primitive nodes for the target graph
    primitives = Paradigm.Canonical.primitive_nodes()

    # Start with primitives in target graph
    initial_target = Paradigm.Graph.insert_nodes(target_graph, primitives)

    # First pass to process records/enums as classes
    source_graph
    |> Paradigm.Graph.get_all_nodes_of_class(["record", "enum"])
    |> Enum.reduce({:ok, initial_target}, fn node_id, {:ok, acc} ->
      case Paradigm.Graph.get_node(source_graph, node_id) do
        nil -> {:error, "Node #{node_id} not found"}
        node -> convert_type_node(node_id, node, acc, source_graph)
      end
    end)
  end

  defp convert_type_node(id, node, target_graph, source_graph) do
    class_id = to_string(id)
    class_name = Paradigm.Graph.get_node_data(source_graph, id, "name", nil)

    case node.class do
      "record" ->
        fields = Paradigm.Graph.get_node_data(source_graph, id, "fields", [])

        {updated_target, properties} =
          Enum.reduce(fields, {target_graph, []}, fn field_id, {acc, props} ->
            case convert_field(field_id, acc, source_graph) do
              {:ok, updated_acc, property_id} -> {updated_acc, props ++ [property_id]}
              {:error, _} = error -> throw(error)
            end
          end)

        final_target =
          Paradigm.Graph.insert_node(updated_target, class_id, "class", %{
            "name" => class_name,
            "is_abstract" => false,
            "owned_attributes" => properties,
            "super_classes" => []
          })

        {:ok, final_target}

      "enum" ->
        symbols = Paradigm.Graph.get_node_data(source_graph, id, "symbols", [])

        final_target =
          Paradigm.Graph.insert_node(target_graph, class_id, "enumeration", %{
            "name" => class_name,
            "literals" => symbols
          })

        {:ok, final_target}
    end
  catch
    {:error, _} = error -> error
  end

  defp convert_field(field_id, target_graph, source_graph) do
    property_id = to_string(field_id)

    field_data = %{
      name: Paradigm.Graph.get_node_data(source_graph, field_id, "name", nil),
      type: Paradigm.Graph.get_node_data(source_graph, field_id, "type", nil),
      doc: Paradigm.Graph.get_node_data(source_graph, field_id, "doc", nil),
      default: Paradigm.Graph.get_node_data(source_graph, field_id, "default", nil),
      is_array: is_array_type?(source_graph, field_id)
    }

    property_node = create_property_node(field_data, source_graph)

    updated_target =
      Paradigm.Graph.insert_node(
        target_graph,
        property_id,
        property_node.class,
        property_node.data
      )

    {:ok, updated_target, property_id}
  end

  defp create_property_node(
         %{name: name, type: type, doc: doc, default: default, is_array: true},
         source_graph
       ) do
    array_items = Paradigm.Graph.get_node_data(source_graph, type, "items", nil)

    %Node{
      class: "property",
      data: %{
        "name" => name,
        "type" => convert_type(array_items),
        "is_ordered" => true,
        "is_composite" => false,
        "lower_bound" => 0,
        "upper_bound" => :infinity,
        "default_value" => default
      }
    }
  end

  defp create_property_node(%{name: name, type: type, doc: doc, default: default}, _source_graph) do
    %Node{
      class: "property",
      data: %{
        "name" => name,
        "type" => convert_type(type),
        "is_ordered" => false,
        "is_composite" => false,
        "lower_bound" => 1,
        "upper_bound" => 1,
        "default_value" => default
      }
    }
  end

  defp is_array_type?(source_graph, field_id) do
    type = Paradigm.Graph.get_node_data(source_graph, field_id, "type", nil)
    node = Paradigm.Graph.get_node(source_graph, type)
    node && node.class == "array"
  end

  defp convert_type(type) do
    Map.get(@type_mapping, type, type)
  end
end
