defmodule ParadigmInterop.Thrift do
  def create_thrift_graph(contents) do
    {:ok, %Thrift.AST.Schema{structs: structs} = schema} = Thrift.Parser.parse_string(contents)

    graph =
      Paradigm.Graph.MapGraph.new()
      |> ParadigmInterop.populate_primitives(~w(bool byte i16 i32 i64 double string))

    structs
    |> Enum.reduce(graph, fn {struct_id, %Thrift.AST.Struct{name: name, fields: fields} = struct},
                             acc_graph ->
      acc_graph
      |> Paradigm.Graph.insert_node("#{struct_id}", "struct", %{
        "name" => "#{name}",
        "fields" =>
          fields
          |> Enum.map(fn field ->
            %Paradigm.Graph.Node.Ref{id: create_field_id(struct, field)}
          end)
      })
      |> create_field_nodes(struct, fields)
    end)
  end

  defp create_field_nodes(graph, struct, fields) do
    fields
    |> Enum.reduce(graph, fn %Thrift.AST.Field{
                               id: _id,
                               name: name,
                               type: type,
                               required: required,
                               default: default
                             } = field,
                             acc_graph ->
      acc_graph
      |> Paradigm.Graph.insert_node(create_field_id(struct, field), "field", %{
        "name" => Atom.to_string(name),
        "type" => %Paradigm.Graph.Node.Ref{id: create_type_reference_id(type)},
        "required" => required == :required,
        "default" => default,
        "is_list" => type_is_list(field.type)
      })
    end)
  end

  defp create_field_id(struct, field), do: "#{struct.name}_#{field.name}"

  defp create_type_reference_id(type) do
    case type do
      {:list, inner_type} -> create_type_reference_id(inner_type)
      %Thrift.AST.TypeRef{referenced_type: type} -> Atom.to_string(type)
      type when is_atom(type) -> Atom.to_string(type)
      _ -> throw("unknown type #{type}")
    end
  end

  defp type_is_list({:list, _}), do: true
  defp type_is_list(_), do: false
end
