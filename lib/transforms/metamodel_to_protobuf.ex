defmodule ParadigmInterop.Transforms.MetamodelToProtobuf do
  @behaviour Paradigm.Transform

  @impl true
  def transform(source_graph, target_graph, _opts) do
    try do
      # Get class nodes and convert to messages
      class_nodes = Paradigm.Graph.get_all_nodes_of_class(source_graph, "class")

      # Get enumeration nodes and convert to enums
      enum_nodes = Paradigm.Graph.get_all_nodes_of_class(source_graph, "enumeration")

      # Process all nodes and insert into target graph
      result =
        Enum.reduce(class_nodes ++ enum_nodes, {:ok, target_graph}, fn node_id, {:ok, acc} ->
          case Paradigm.Graph.get_node(source_graph, node_id) do
            nil ->
              {:error, "Node #{node_id} not found"}

            node ->
              case node.class do
                "class" ->
                  case create_message(node_id, node, source_graph) do
                    {:ok, message_class, message_data} ->
                      {:ok, Paradigm.Graph.insert_node(acc, node_id, message_class, message_data)}

                    error ->
                      error
                  end

                "enumeration" ->
                  case create_enum(node_id, node, source_graph) do
                    {:ok, enum_class, enum_data} ->
                      {:ok, Paradigm.Graph.insert_node(acc, node_id, enum_class, enum_data)}

                    error ->
                      error
                  end

                _ ->
                  {:error, "Unsupported node class: #{node.class}"}
              end
          end
        end)

      result
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp create_message(id, _node, graph) do
    # Create fields from class attributes
    owned_attrs = Paradigm.Graph.get_node_data(graph, id, "owned_attributes", [])

    fields =
      owned_attrs
      |> Enum.with_index(1)
      |> Enum.map(fn {attr_id, index} ->
        create_field(attr_id, index, graph)
      end)

    # Create the message data
    message_data = %{
      "name" => Paradigm.Graph.get_node_data(graph, id, "name", ""),
      "fields" => fields,
      "nested_messages" => []
    }

    {:ok, "message", message_data}
  end

  defp create_field(property_id, field_number, graph) do
    type = Paradigm.Graph.get_node_data(graph, property_id, "type", "")

    # Determine field label based on bounds
    label =
      cond do
        Paradigm.Graph.get_node_data(graph, property_id, "upper_bound", 1) == :infinity ->
          "repeated"

        Paradigm.Graph.get_node_data(graph, property_id, "lower_bound", 1) == 0 ->
          "optional"

        true ->
          "required"
      end

    # Convert type name to protobuf type
    pb_type =
      case type do
        "string" -> "string"
        "integer" -> "int32"
        "boolean" -> "bool"
        "float" -> "float"
        # Default to message type for complex types
        _ -> "message"
      end

    %{
      "name" => Paradigm.Graph.get_node_data(graph, property_id, "name", ""),
      "type" => pb_type,
      "number" => field_number,
      "label" => label
    }
  end

  defp create_enum(id, _node, graph) do
    # Create enum values from literals
    literals = Paradigm.Graph.get_node_data(graph, id, "literals", [])

    values =
      literals
      |> Enum.with_index()
      |> Enum.map(fn {literal_id, index} ->
        %{
          "name" => Paradigm.Graph.get_node_data(graph, literal_id, "name", ""),
          "number" => index
        }
      end)

    # Create the enum data
    enum_data = %{
      "name" => Paradigm.Graph.get_node_data(graph, id, "name", ""),
      "values" => values,
      "parent_message" => nil
    }

    {:ok, "enum", enum_data}
  end
end
