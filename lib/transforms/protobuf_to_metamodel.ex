defmodule ParadigmInterop.Transforms.ProtobufToMetamodel do
  @behaviour Paradigm.Transform

  @impl true
  def transform(source_graph, target_graph, _opts) do
    try do
      # Create package first
      package_id = "package_1"

      package_data = %{
        "name" => "protobuf",
        "uri" => "http://example.org/protobuf",
        "nested_packages" => [],
        "owned_types" => []
      }

      target_graph = Paradigm.Graph.insert_node(target_graph, package_id, "package", package_data)

      # Transform all messages to classes
      message_ids = Paradigm.Graph.get_all_nodes_of_class(source_graph, "message")

      {target_graph, _} =
        message_ids
        |> Enum.reduce({target_graph, %{}}, fn id, {acc_graph, properties} ->
          class_id = "class_#{id}"

          class_data = %{
            "name" => Paradigm.Graph.get_node_data(source_graph, id, "message_name", ""),
            "is_abstract" => false,
            "owned_attributes" => [],
            "super_classes" => []
          }

          acc_graph = Paradigm.Graph.insert_node(acc_graph, class_id, "class", class_data)

          # Transform message fields to properties
          field_ids = Paradigm.Graph.get_node_data(source_graph, id, "message_fields", [])
          acc_graph = create_properties_from_fields(source_graph, acc_graph, field_ids)

          {acc_graph, properties}
        end)

      # Transform all enums to enumerations
      enum_ids = Paradigm.Graph.get_all_nodes_of_class(source_graph, "enum")

      target_graph =
        enum_ids
        |> Enum.reduce(target_graph, fn id, acc_graph ->
          enum_id = "enum_#{id}"

          enumeration_data = %{
            "name" => Paradigm.Graph.get_node_data(source_graph, id, "enum_name", ""),
            "literals" => []
          }

          acc_graph =
            Paradigm.Graph.insert_node(acc_graph, enum_id, "enumeration", enumeration_data)

          # Transform enum values to enumeration literals
          value_ids = Paradigm.Graph.get_node_data(source_graph, id, "enum_values", [])
          create_literals_from_values(source_graph, acc_graph, value_ids)
        end)

      {:ok, target_graph}
    rescue
      e -> {:error, "Transform failed: #{inspect(e)}"}
    end
  end

  defp create_properties_from_fields(source_graph, target_graph, field_ids) do
    field_ids
    |> Enum.reduce(target_graph, fn field_id, acc_graph ->
      prop_id = "property_#{field_id}"

      property_data = %{
        "name" => Paradigm.Graph.get_node_data(source_graph, field_id, "field_name", ""),
        "type" => Paradigm.Graph.get_node_data(source_graph, field_id, "field_type", ""),
        "is_ordered" => false,
        "is_composite" => false,
        "lower_bound" => 0,
        "upper_bound" => 1,
        "default_value" => nil
      }

      Paradigm.Graph.insert_node(acc_graph, prop_id, "property", property_data)
    end)
  end

  defp create_literals_from_values(source_graph, target_graph, value_ids) do
    value_ids
    |> Enum.reduce(target_graph, fn value_id, acc_graph ->
      lit_id = "literal_#{value_id}"

      literal_data = %{
        "name" => Paradigm.Graph.get_node_data(source_graph, value_id, "enum_value_name", "")
      }

      Paradigm.Graph.insert_node(acc_graph, lit_id, "enumeration_literal", literal_data)
    end)
  end
end
