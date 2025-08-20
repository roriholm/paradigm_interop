defmodule ParadigmInterop do
  @moduledoc """
  Documentation for `ParadigmInterop`.
  """

  def populate_primitives(graph, primitive_names) do
    primitive_names
    |> Enum.reduce(graph, fn prim, acc ->
      Paradigm.Graph.insert_node(acc, prim, "primitive", %{name: prim})
    end)
  end
end
