defmodule ParadigmInterop.Avro do
  def create_avro_graph(contents) do
    {:ok, %AvroEx.Schema{context: %{names: records}, schema: %{fields: fields}} = avro_schema} =
      AvroEx.decode_schema(contents)

    baseline_graph =
      Paradigm.Graph.MapGraph.new()
      |> ParadigmInterop.populate_primitives(~w(null boolean int long float double bytes string))

    records
    |> Enum.reduce(
      baseline_graph,
      fn {id,
          %AvroEx.Schema.Record{
            fields: fields,
            name: name,
            namespace: namespace,
            aliases: aliases,
            doc: doc
          }},
         acc ->
        acc
        |> Paradigm.Graph.insert_node(id, "record", %{
          name: name,
          aliases: aliases,
          doc: doc,
          namespace: namespace
        })
        |> insert_fields(id, fields)
      end
    )
  end

  defp insert_fields(graph, message_name, fields) do
    Enum.reduce(fields, graph, fn field, acc ->
      field_id = "#{message_name}_#{field.name}"

      Paradigm.Graph.insert_node(acc, field_id, "field", %{
        name: to_string(field.name),
        type: %Paradigm.Graph.Node.Ref{id: pointer_to(field.type)},
        default: field.default,
        aliases: field.aliases
      })
      |> maybe_create_array_node(field.type)
    end)
  end

  defp maybe_create_array_node(graph, %AvroEx.Schema.Array{items: type} = array) do
    array_id = pointer_to(array)

    Paradigm.Graph.insert_node(graph, array_id, "array", %{
      name: array_id,
      items: %Paradigm.Graph.Node.Ref{id: pointer_to(type)}
    })
  end

  defp maybe_create_array_node(graph, _), do: graph

  defp pointer_to(%AvroEx.Schema.Primitive{type: name}), do: to_string(name)

  defp pointer_to(%AvroEx.Schema.Record{name: name}), do: name

  defp pointer_to(%AvroEx.Schema.Array{items: type}), do: "#{pointer_to(type)}_array"
end
