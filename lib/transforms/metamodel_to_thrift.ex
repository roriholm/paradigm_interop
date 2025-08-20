defmodule ParadigmInterop.Transforms.MetamodelToThrift do
  @behaviour Paradigm.Transform

  # @type_mapping %{
  #   "boolean" => "bool",
  #   "integer" => "byte",
  #   "integer" => "i32",
  #   "float" => "double",
  #   "string" => "string",
  # }

  @impl true
  def transform(source_graph, target_graph, _opts) do
    case create_thrift_nodes(source_graph) do
      {:ok, nodes} ->
        result = Paradigm.Graph.insert_nodes(target_graph, nodes)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_thrift_nodes(graph) do
    class_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "class")

    Enum.reduce_while(class_nodes, {:ok, %{}}, fn node_id, {:ok, acc} ->
      case Paradigm.Graph.get_node(graph, node_id) do
        nil ->
          {:halt, {:error, "Node #{node_id} not found"}}

        _node ->
          struct_id = to_string(node_id)
          struct_name = Paradigm.Graph.get_node_data(graph, node_id, "name", nil)
          is_abstract = Paradigm.Graph.get_node_data(graph, node_id, "is_abstract", false)

          result =
            if is_abstract do
              process_abstract_fields(node_id, graph, acc)
            else
              process_concrete_fields(node_id, graph, acc)
            end

          case result do
            {:ok, {fields, acc_with_fields}} ->
              updated_acc =
                Map.put(acc_with_fields, struct_id, %{
                  class: if(is_abstract, do: "union", else: "struct"),
                  data: %{
                    "name" => struct_name,
                    "fields" => fields
                  }
                })

              {:cont, {:ok, updated_acc}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp process_abstract_fields(id, graph, acc) do
    class_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "class")

    sub_classes =
      Enum.filter(class_nodes, fn sub_id ->
        super_classes = Paradigm.Graph.get_node_data(graph, sub_id, "super_classes", [])
        to_string(id) in Enum.map(super_classes, &to_string/1)
      end)

    {fields, updated_acc} =
      Enum.map_reduce(sub_classes, acc, fn sub_id, acc ->
        type_id = to_string(sub_id)
        field_id = "#{id}_#{type_id}"
        field_name = String.downcase(Paradigm.Graph.get_node_data(graph, sub_id, "name", ""))

        updated_acc =
          Map.put(acc, field_id, %{
            class: "field",
            data: %{
              "name" => field_name,
              "type" => type_id,
              "required" => false,
              "default" => nil,
              "is_list" => false
            }
          })

        {field_id, updated_acc}
      end)

    {:ok, {fields, updated_acc}}
  end

  defp process_concrete_fields(id, graph, acc) do
    super_classes = Paradigm.Graph.get_node_data(graph, id, "super_classes", [])

    all_fields =
      super_classes
      |> Enum.flat_map(fn super_class ->
        Paradigm.Graph.get_node_data(graph, super_class, "owned_attributes", [])
      end)
      |> Enum.concat(Paradigm.Graph.get_node_data(graph, id, "owned_attributes", []))

    {fields, updated_acc} = Enum.map_reduce(all_fields, acc, &process_field(&1, &2, graph))
    {:ok, {fields, updated_acc}}
  end

  defp process_field(property_id, acc, graph) do
    field_id = to_string(property_id)
    field_name = Paradigm.Graph.get_node_data(graph, property_id, "name", nil)
    field_type = Paradigm.Graph.get_node_data(graph, property_id, "type", nil)
    field_default = Paradigm.Graph.get_node_data(graph, property_id, "default_value", nil)
    field_required = Paradigm.Graph.get_node_data(graph, property_id, "lower_bound", 0) > 0
    field_is_list = Paradigm.Graph.get_node_data(graph, property_id, "upper_bound", 1) > 1

    updated_acc =
      Map.put(acc, field_id, %{
        class: "field",
        data: %{
          "name" => field_name,
          "type" => convert_type(field_type),
          "required" => field_required,
          "default" => field_default,
          "is_list" => field_is_list
        }
      })

    {field_id, updated_acc}
  end

  defp convert_type(type) do
    case type do
      "boolean" -> "bool"
      "float" -> "double"
      "integer" -> "i32"
      "string" -> "string"
      "void" -> nil
      other -> other
    end
  end
end
