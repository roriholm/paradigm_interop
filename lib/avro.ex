defmodule ParadigmInterop.Avro do
  def create_avro_graph(contents) do
    {:ok, %AvroEx.Schema{context: %{names: records}, schema: %{fields: fields}} = avro_schema} =
      AvroEx.decode_schema(contents)

    # IO.inspect(records)
    false
  end

  defp convert_to_graph(avro) do
    graph =
      %{}
      |> Paradigm.Canonical.Avro.inject_primitive_nodes()

    main_record = avro.schema
    graph = process_record(graph, main_record)

    # Process any referenced types from context
    Enum.reduce(avro.context.names, graph, fn {_name, type}, acc ->
      case type do
        %AvroEx.Schema.Record{} ->
          process_record(acc, type)

        _ ->
          acc
      end
    end)
  end

  defp process_record(graph, record) do
    record_id = "#{record.name}"

    # First process all fields to collect their IDs
    {graph, field_ids} =
      Enum.reduce(record.fields, {graph, []}, fn field, {acc_graph, acc_ids} ->
        field_id = "#{record_id}_#{field.name}"
        {graph, field_type_id} = process_type(acc_graph, field.type)

        updated_graph =
          Map.put(graph, field_id, %Paradigm.Graph.Node{
            class: "field",
            data: %{
              "name" => field.name,
              "type" => field_type_id,
              "doc" => field.doc,
              "default" => field.default,
              "aliases" => field.aliases || []
            }
          })

        {updated_graph, [field_id | acc_ids]}
      end)

    # Create node for the record with field IDs
    Map.put(graph, record_id, %Paradigm.Graph.Node{
      class: "record",
      data: %{
        "name" => record.name,
        "namespace" => record.namespace,
        "doc" => record.doc,
        "aliases" => record.aliases || [],
        "fields" => Enum.reverse(field_ids)
      }
    })
  end

  defp process_type(graph, type) do
    case type do
      %AvroEx.Schema.Primitive{type: primitive_type} ->
        {graph, "#{primitive_type}"}

      %AvroEx.Schema.Record{} ->
        {graph, "#{type.name}"}

      %AvroEx.Schema.Array{items: items} ->
        array_id = "#{type.items.name}_array"
        {graph, items_id} = process_type(graph, items)

        updated_graph =
          Map.put(graph, array_id, %Paradigm.Graph.Node{
            class: "array",
            data: %{"name" => array_id, "items" => items_id}
          })

        {updated_graph, array_id}

      _ ->
        {graph, type.name}
    end
  end
end
