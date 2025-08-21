defmodule ParadigmInterop do
  @moduledoc """
  Documentation for `ParadigmInterop`.
  """
  alias Paradigm.Universe
  alias ParadigmInterop.Paradigms

  def populate_primitives(graph, primitive_names) do
    primitive_names
    |> Enum.reduce(graph, fn prim, acc ->
      Paradigm.Graph.insert_node(acc, prim, "primitive", %{name: prim})
    end)
  end

  def bootstrap() do
    Universe.bootstrap("Interop Universe", "The land of Protobuf, Avro, Thrift")
    |> Universe.insert_paradigm(Paradigms.Thrift.definition())
    |> Universe.insert_paradigm(Paradigms.Avro.definition())
    |> Universe.insert_paradigm(Paradigms.Protobuf.definition())
    |> Universe.apply_propagate()
  end
end
