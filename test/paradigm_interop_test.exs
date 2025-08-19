defmodule ParadigmInteropTest do
  use ExUnit.Case
  doctest ParadigmInterop

  test "schemas" do
    filesystem_graph = Paradigm.Graph.FilesystemGraph.new(root: ".test/data/vehicle_model")

    {:ok, schema_graph} =
      ParadigmInterop.ParseSchemas.transform(filesystem_graph, Paradigm.Graph.MapGraph.new(), %{})

    schema_paradigm = ParadigmInterop.Paradigms.Schema.definition()

    assert %Paradigm.Conformance.Result{issues: []} =
             Paradigm.Conformance.check_graph(schema_paradigm, schema_graph)
  end
end
